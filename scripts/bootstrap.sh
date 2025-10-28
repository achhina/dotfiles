#!/usr/bin/env bash

set -euo pipefail

readonly REPO_URL="https://github.com/achhina/dotfiles.git"
readonly CONFIG_DIR="${HOME}/.config"
readonly NIX_CONF_DIR="${HOME}/.config/nix"

log() {
    printf '%s\n' "$1" >&2
}

error() {
    log "ERROR: $1"
    exit 1
}

detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            error "Unsupported platform: $(uname -s)"
            ;;
    esac
}

detect_architecture() {
    uname -m
}

warn_architecture_migration() {
    local arch
    arch=$(detect_architecture)
    local platform
    platform=$(detect_platform)

    log "Detected architecture: ${arch}"

    if [[ "${platform}" == "macos" ]]; then
        if [[ "${arch}" == "arm64" ]]; then
            log "WARNING: Running on Apple Silicon (arm64)"
            log "   If migrating from Intel Mac, ensure:"
            log "   - Remove ~/.cache directory (contains x86_64 binaries)"
            log "   - Add trusted-users = root @admin to /etc/nix/nix.conf after install"
            log "   - Use Homebrew at /opt/homebrew (not /usr/local)"
        elif [[ "${arch}" == "x86_64" ]]; then
            log "Running on Intel Mac (x86_64)"
        fi
    fi
}

check_nix_installed() {
    command -v nix-env >/dev/null 2>&1
}

check_and_remove_broken_symlinks() {
    log "Checking for broken symlinks in ${CONFIG_DIR}..."
    local broken_links=()

    if [[ ! -d "${CONFIG_DIR}" ]]; then
        log "No ${CONFIG_DIR} directory exists yet"
        return 0
    fi

    # Find broken symlinks
    while IFS= read -r -d '' link; do
        if [[ -L "${link}" ]] && [[ ! -e "${link}" ]]; then
            broken_links+=("${link}")
        fi
    done < <(find "${CONFIG_DIR}" -type l -print0 2>/dev/null)

    if [[ ${#broken_links[@]} -eq 0 ]]; then
        log "No broken symlinks found"
        return 0
    fi

    log "WARNING: Found ${#broken_links[@]} broken symlink(s):"
    printf '  - %s\n' "${broken_links[@]}"

    printf '\nThese are likely from a previous Home Manager installation.\n'
    printf 'Remove them? [y/N]: '
    read -r response

    if [[ "${response}" =~ ^[Yy]$ ]]; then
        for link in "${broken_links[@]}"; do
            rm -f "${link}"
            log "  Removed: ${link}"
        done
        log "Broken symlinks removed"
    else
        log "Skipping broken symlink removal"
        log "WARNING: These may cause issues during bootstrap"
    fi
}

check_nix_backups() {
    log "Checking for pre-existing Nix backup files..."
    local backup_files=(
        "/etc/bash.bashrc.backup-before-nix"
        "/etc/zshrc.backup-before-nix"
        "/etc/bashrc.backup-before-nix"
    )
    local found_backups=()

    for backup in "${backup_files[@]}"; do
        if [[ -f "${backup}" ]]; then
            found_backups+=("${backup}")
        fi
    done

    if [[ ${#found_backups[@]} -eq 0 ]]; then
        log "No pre-existing Nix backups found"
        return 0
    fi

    log "WARNING: Found ${#found_backups[@]} pre-existing Nix backup file(s):"
    printf '  - %s\n' "${found_backups[@]}"

    printf '\nThese are likely from a previous Nix installation or migration.\n'
    printf 'The Nix installer will fail if these exist.\n'
    printf 'Remove them? [y/N]: '
    read -r response

    if [[ "${response}" =~ ^[Yy]$ ]]; then
        for backup in "${found_backups[@]}"; do
            sudo rm -f "${backup}"
            log "  Removed: ${backup}"
        done
        log "Backup files removed"
    else
        log "WARNING: Nix installer will likely fail with these present"
        printf 'Continue anyway? [y/N]: '
        read -r continue_response
        if [[ ! "${continue_response}" =~ ^[Yy]$ ]]; then
            error "Bootstrap aborted. Please handle backup files manually."
        fi
    fi
}

install_nix() {
    local platform
    platform=$(detect_platform)

    log "Installing Nix for ${platform}..."

    if [[ "${platform}" == "macos" ]]; then
        sh <(curl -L https://nixos.org/nix/install)
    else
        sh <(curl -L https://nixos.org/nix/install) --daemon
    fi

    # Source nix profile to make nix commands available
    if [[ -e "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
        # shellcheck source=/dev/null
        . "${HOME}/.nix-profile/etc/profile.d/nix.sh"
    fi
}

enable_flakes() {
    log "Enabling Nix flakes..."

    mkdir -p "${NIX_CONF_DIR}"

    if ! grep -q "experimental-features.*flakes" "${NIX_CONF_DIR}/nix.conf" 2>/dev/null; then
        echo "experimental-features = nix-command flakes" >> "${NIX_CONF_DIR}/nix.conf"
        log "Flakes enabled in ${NIX_CONF_DIR}/nix.conf"
    else
        log "Flakes already enabled"
    fi
}

get_hostname() {
    local platform
    platform=$(detect_platform)

    if [[ "${platform}" == "macos" ]]; then
        scutil --get LocalHostName
    else
        hostname
    fi
}

handle_config_conflicts() {
    local temp_dir
    temp_dir=$(mktemp -d)
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="${CONFIG_DIR}.backup.${timestamp}"

    log "Cloning repository to temporary location..."
    git clone "${REPO_URL}" "${temp_dir}"

    if [[ ! -d "${CONFIG_DIR}" ]]; then
        log "No existing ${CONFIG_DIR}, moving cloned repo..."
        mv "${temp_dir}" "${CONFIG_DIR}"
        return 0
    fi

    log "Checking for conflicts with existing ${CONFIG_DIR}..."
    local conflicts=()

    # Find all items in the temp clone
    while IFS= read -r -d '' item; do
        local rel_path="${item#"${temp_dir}"/}"
        # Skip .git directory from comparison
        [[ "${rel_path}" == ".git" ]] && continue
        [[ "${rel_path}" == .git/* ]] && continue

        if [[ -e "${CONFIG_DIR}/${rel_path}" ]]; then
            # Get the top-level directory/file that conflicts
            local top_level
            top_level=$(echo "${rel_path}" | cut -d/ -f1)

            # Only add unique top-level conflicts
            local pattern=" ${top_level} "
            if [[ ! " ${conflicts[*]:-} " =~ $pattern ]]; then
                conflicts+=("${top_level}")
            fi
        fi
    done < <(find "${temp_dir}" -mindepth 1 -print0)

    if [[ ${#conflicts[@]} -eq 0 ]]; then
        log "No conflicts found. Initializing git in ${CONFIG_DIR}..."
        cd "${CONFIG_DIR}"
        git init
        git remote add origin "${REPO_URL}"
        git fetch
        git reset --hard origin/main
        rm -rf "${temp_dir}"
        return 0
    fi

    log "Found ${#conflicts[@]} conflicting directories/files:"
    printf '  - %s\n' "${conflicts[@]}"

    printf '\nOptions:\n'
    printf '  1) Backup conflicts and initialize in place (recommended)\n'
    printf '  2) Abort and handle manually\n'
    printf 'Choose [1-2]: '
    read -r choice

    case "${choice}" in
        1)
            mkdir -p "${backup_dir}"
            log "Backing up conflicts to ${backup_dir}..."

            for item in "${conflicts[@]}"; do
                if [[ -e "${CONFIG_DIR}/${item}" ]]; then
                    mv "${CONFIG_DIR}/${item}" "${backup_dir}/${item}"
                    log "  Backed up: ${item}"
                fi
            done

            log "Initializing git in ${CONFIG_DIR}..."
            cd "${CONFIG_DIR}"
            git init
            git remote add origin "${REPO_URL}"
            git fetch
            git reset --hard origin/main

            log "Backup created at: ${backup_dir}"
            log "You can manually merge needed configs from the backup later."
            ;;
        2)
            log "Aborting. Please handle ${CONFIG_DIR} manually and re-run this script."
            rm -rf "${temp_dir}"
            exit 0
            ;;
        *)
            error "Invalid choice"
            ;;
    esac

    rm -rf "${temp_dir}"
}

bootstrap_home_manager() {
    local hostname
    hostname=$(get_hostname)

    log "Bootstrapping Home Manager for hostname: ${hostname}"

    cd "${CONFIG_DIR}"

    # Source nix profile if not already in environment
    if ! command -v nix >/dev/null 2>&1; then
        if [[ -e "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
            # shellcheck source=/dev/null
            . "${HOME}/.nix-profile/etc/profile.d/nix.sh"
        fi
    fi

    log "Running first Home Manager activation..."
    nix run home-manager/master -- switch --flake "${NIX_CONF_DIR}#${hostname}"

    log ""
    log "✓ Bootstrap complete!"
    log ""
    log "Next steps:"
    log "  1. Restart your shell (or run: exec \$SHELL)"
    log "  2. Aliases will be available (hm, update, etc.)"
    log "  3. Run 'update' to update and rebuild"
    log "  4. See README.md for daily operations"
}

main() {
    log "=== Dotfiles Bootstrap Script ==="
    log ""

    # Warn about architecture and migration considerations
    warn_architecture_migration
    log ""

    # Check for broken symlinks from previous installations
    check_and_remove_broken_symlinks
    log ""

    # Check and install Nix
    if ! check_nix_installed; then
        # Check for pre-existing Nix backups before installing
        check_nix_backups
        log ""
        install_nix
    else
        log "Nix already installed"
    fi

    # Enable flakes
    enable_flakes

    # Handle config directory conflicts
    handle_config_conflicts

    # Bootstrap Home Manager
    bootstrap_home_manager
}

main "$@"
