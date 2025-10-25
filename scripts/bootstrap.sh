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

check_nix_installed() {
    command -v nix-env >/dev/null 2>&1
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
            if [[ ! " ${conflicts[*]} " =~ $pattern ]]; then
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

    # Check and install Nix
    if ! check_nix_installed; then
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
