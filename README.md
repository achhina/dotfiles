# Dotfiles

Personal dotfiles managed with Nix flakes and Home Manager for reproducible development environments across macOS and Linux.

## Table of Contents
- [🚀 First Time Setup](#-first-time-setup)
  - [Quick Bootstrap](#quick-bootstrap-recommended)
  - [Manual Installation](#manual-installation-for-debugging-or-understanding-the-process)
- [⚡ Daily Operations](#-daily-operations)
  - [Updating the System](#updating-the-system)
  - [Adding Packages](#adding-packages)
  - [Managing Configurations](#managing-configurations)
  - [Development Shells](#development-shells)
- [🔧 Troubleshooting & Migration](#-troubleshooting--migration)
  - [Common Issues](#common-issues)
  - [Machine Migration](#machine-migration)
  - [Getting Help](#getting-help)

## 🚀 First Time Setup

### Quick Bootstrap (Recommended)

Run this one-liner to set up everything automatically:

```bash
bash <(curl -L https://raw.githubusercontent.com/achhina/dotfiles/main/scripts/bootstrap.sh)
```

The script handles:
- Architecture detection and migration warnings (Intel ↔ Apple Silicon)
- Broken symlink cleanup from previous installations
- Pre-existing Nix backup file detection and removal
- Nix installation (with platform detection) or skips if already installed
- Enabling flakes before they're needed
- Smart ~/.config conflict resolution
- Home Manager bootstrap with correct flake path
- First activation

The bootstrap script has been hardened for machine migrations and architecture changes.

---

### Manual Installation (for debugging or understanding the process)

If you prefer to run commands manually or the bootstrap script fails, follow these steps:

#### 1. Install Nix

**macOS:**
```bash
sh <(curl -L https://nixos.org/nix/install)
```

**Linux:**
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

#### 2. Enable Flakes

**⚠️ CRITICAL:** Must be done BEFORE using the flake:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

#### 3. Clone Repository

**⚠️ ~/.config COLLISION GOTCHA:** You can't clone into an existing directory with contents.

**Option A: Backup and clean clone**
```bash
# Backup existing config if needed
mv ~/.config ~/.config.backup
git clone https://github.com/achhina/dotfiles.git ~/.config
# Manually merge back any needed configs from ~/.config.backup
```

**Option B: Initialize in place**
```bash
cd ~/.config
git init
git remote add origin https://github.com/achhina/dotfiles.git
git fetch
git reset --hard origin/main  # ⚠️ WARNING: Overwrites local files
```

#### 4. Bootstrap Home Manager

**⚠️ FIRST-RUN GOTCHA:** Aliases aren't configured yet, use full command:

**macOS:**
```bash
nix run home-manager/master -- switch --flake ~/.config/nix#$(scutil --get LocalHostName)
```

**Linux:**
```bash
nix run home-manager/master -- switch --flake ~/.config/nix#$(hostname)
```

#### 5. Restart Shell

```bash
exec $SHELL
```

The next shell session will have all aliases and configurations active.

## ⚡ Daily Operations

Quick reference for common tasks (assumes working setup).

### Updating the System

Update flake inputs and rebuild:
```bash
update
```

Update and clean old generations (garbage collection):
```bash
update -c
```

### Adding Packages

Edit the package list:
```bash
nvim ~/.config/nix/home-manager/modules/packages.nix
```

Apply changes:
```bash
hm switch
```

The `hm` alias automatically points to your flake (`~/.config/nix`).

Verify package available:
```bash
command -v package-name
```

### Managing Configurations

**Most configs are in Home Manager modules**, not application config files:

```bash
# Find the Home Manager module first (declarative source of truth)
ls ~/.config/nix/home-manager/modules/

# Edit module (examples)
nvim ~/.config/nix/home-manager/modules/claude.nix
nvim ~/.config/nix/home-manager/modules/shell.nix
nvim ~/.config/nix/home-manager/modules/git.nix

# Apply changes
hm switch
```

**⚠️ NEVER edit generated symlinks** (they point to /nix/store and will be overwritten).

### Development Shells

Enter isolated development environment:
```bash
nix develop .#python    # Python environment
nix develop .#node      # Node.js environment
nix develop .#rust      # Rust environment
nix develop .#go        # Go environment
```

Available shells defined in: `~/.config/nix/modules/devshells.nix`

## 🔧 Troubleshooting & Migration

### Common Issues

If you encounter problems during setup or migration:

**Bootstrap script automatically handles:**
- Broken symlinks from previous installations
- Pre-existing Nix backup files
- Architecture-specific warnings (Intel ↔ Apple Silicon)

**For manual intervention required:**
- See [docs/troubleshooting.md](docs/troubleshooting.md) for comprehensive edge case coverage
- PAM/Touch ID configuration for Apple Silicon
- Docker architecture setup
- Homebrew dual-installation cleanup
- Development environment issues

### Machine Migration

When migrating to a new machine (especially Intel → Apple Silicon):

1. **Pre-migration:** Clean up caches and old artifacts (see troubleshooting guide)
2. **Bootstrap:** Run the bootstrap script - it detects architecture and handles common issues
3. **Post-migration:** Follow verification steps in troubleshooting guide

The bootstrap script has been hardened based on real-world M4 MacBook migration experience.

### Getting Help

- **Architecture details:** See [AGENTS.md](AGENTS.md) for system organization
- **Troubleshooting:** See [docs/troubleshooting.md](docs/troubleshooting.md)
- **Bootstrap script issues:** Check script output for specific error messages
