# Troubleshooting Guide

This guide covers common issues and edge cases when setting up or migrating your dotfiles. These are problems that can't be systematically prevented and require manual intervention. The bootstrap script handles many issues automatically, but this guide documents the failures it can't address and how to resolve them manually.

## Table of Contents
- [Machine Migration](#machine-migration)
  - [Pre-Migration Checklist](#pre-migration-checklist)
  - [Using macOS Migration Assistant](#using-macos-migration-assistant)
  - [Post-Migration Verification](#post-migration-verification)
- [Architecture-Specific Issues](#architecture-specific-issues)
  - [Intel → Apple Silicon Migration](#intel--apple-silicon-migration)
  - [PAM/Touch ID Configuration](#pamtouch-id-configuration)
  - [Docker Architecture Setup](#docker-architecture-setup)
  - [Homebrew Dual Installation](#homebrew-dual-installation)
- [Common Issues & Solutions](#common-issues--solutions)
- [Development Environment Issues](#development-environment-issues)
- [Quick Reference](#quick-reference)

---

## Machine Migration

### Pre-Migration Checklist

Before using Migration Assistant or manually transferring files, complete these steps on the **source machine**:

### 1. Clean Up Old Installation Artifacts

```bash
# Remove Nix installation backups (will be recreated on target)
sudo rm -f /etc/bash.bashrc.backup-before-nix
sudo rm -f /etc/zshrc.backup-before-nix
sudo rm -f /etc/bashrc.backup-before-nix

# Remove cached binaries (architecture-specific)
rm -rf ~/.cache

# Optional: Review and clean Nix store (reclaim space)
nix-collect-garbage -d
```

### 2. Document Custom PAM Configurations

If you've modified `/etc/pam.d/sudo` or `/etc/pam.d/sudo_local`:

```bash
# Back up your PAM configs
cp /etc/pam.d/sudo ~/Documents/pam-sudo.backup
cp /etc/pam.d/sudo_local ~/Documents/pam-sudo_local.backup 2>/dev/null || true
```

**Note:** PAM modules like `pam_reattach.so` are architecture-specific and will need to be reinstalled on the target machine.

### 3. Commit Dotfiles Changes

```bash
cd ~/.config
git status
git add -A
git commit -m "Pre-migration: sync all changes"
git push origin main
```

### 4. Document Homebrew Packages (macOS)

```bash
# List all Homebrew packages
brew list --formula > ~/Documents/brew-formulas.txt
brew list --cask > ~/Documents/brew-casks.txt

# Note: These are for reference. Most should be managed by Nix or will need arm64 versions.
```

---

### Using macOS Migration Assistant

### What Transfers Well
- Application data and preferences
- Documents and media files
- Bitwarden/1Password data
- Git repository contents (including `.git` directories)

### What Causes Issues
- **Nix store** - Contains architecture-specific binaries
- **Home Manager symlinks** - Point to old Nix store paths
- **Cache directories** - Contain compiled binaries for wrong architecture
- **Homebrew installations** - `/usr/local` (Intel) vs `/opt/homebrew` (Apple Silicon)
- **PAM modules** - Architecture-specific shared libraries

### Migration Assistant Process

1. On the **new machine**, go through first-time setup but **do not** run dotfiles bootstrap yet
2. Use Migration Assistant when prompted (or via System Settings → General → Transfer or Reset)
3. Select your source Mac or Time Machine backup
4. Choose what to transfer (select all unless you have specific reasons)
5. Wait for transfer to complete (~1 hour for 500GB)
6. Complete initial macOS setup (sign into iCloud, etc.)

### Post-Migration Assistant Steps

The bootstrap script now handles most cleanup automatically, but be aware:

```bash
# The bootstrap script will detect and offer to:
# 1. Remove broken symlinks from old Home Manager
# 2. Remove old Nix backup files
# 3. Warn about architecture-specific considerations
```

---

## Architecture-Specific Issues

### Intel → Apple Silicon Migration

### Critical Considerations

When migrating from Intel (x86_64) to Apple Silicon (arm64):

1. **Rosetta 2 Translation**: Not installed by default. System will prompt when needed.
2. **Homebrew Location**:
   - Intel: `/usr/local/bin/brew`
   - Apple Silicon: `/opt/homebrew/bin/brew`
3. **Docker Architecture**: Default images are often amd64, need explicit arm64
4. **Nix Store**: All binaries must be rebuilt for arm64

#### Step-by-Step Process

##### 1. Initial Permissions

After Migration Assistant, grant required permissions:

**System Settings → Privacy & Security → Accessibility:**
- BetterTouchTool
- Logi Options++
- Aerospace (after Home Manager runs)
- Borders/jankyborders (after Home Manager runs)

**System Settings → Privacy & Security → Screen Recording:**
- BetterTouchTool
- Any recording/streaming apps

**System Settings → Privacy & Security → Input Monitoring:**
- Karabiner-Elements

##### 2. Fix PAM for sudo (If You Use Touch ID with tmux)

If you get `sudo: unable to initialize PAM: Undefined error: 0`:

**Temporary Fix (restore sudo functionality):**
```bash
# Open /etc/pam.d in Finder to modify protected files
open /etc/pam.d/

# In Finder: select 'sudo', Get Info, unlock, temporarily grant read/write
# Edit /etc/pam.d/sudo - comment out or remove this line:
# auth       include        sudo_local

# Test sudo works
sudo echo "test"

# Restore read-only permissions via Finder
```

**Permanent Fix (restore Touch ID):**
```bash
# Install Apple Silicon Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install arm64 pam-reattach
/opt/homebrew/bin/brew install pam-reattach

# Create /etc/pam.d/sudo_local with:
echo "auth       optional       /opt/homebrew/lib/pam/pam_reattach.so" | sudo tee /etc/pam.d/sudo_local

# Verify architecture
file /opt/homebrew/lib/pam/pam_reattach.so
# Should show: Mach-O 64-bit bundle arm64

# Restore include in /etc/pam.d/sudo (same Finder trick)
# Add this line at the top:
# auth       include        sudo_local

# Test
sudo echo "test"  # Should work with Touch ID
```

The Homebrew PATH is automatically configured in Home Manager (`shell.nix`).

##### 3. Clean Up Migrated Files

```bash
# Remove broken symlinks (or let bootstrap script handle it)
find ~/.config -type l ! -exec test -e {} \; -print | xargs rm -f

# Remove architecture-specific caches
rm -rf ~/.cache
rm -rf ~/.local/share/nvim  # Neovim plugins will reinstall
```

##### 4. Run Bootstrap

Now run the bootstrap script. It will automatically:
- Detect arm64 architecture and warn about migration considerations
- Check for broken symlinks and offer to remove them
- Check for old Nix backup files and offer to remove them
- Install Nix for arm64
- Bootstrap Home Manager with arm64 packages

```bash
bash <(curl -L https://raw.githubusercontent.com/achhina/dotfiles/main/scripts/bootstrap.sh)
```

##### 5. Configure Nix as Trusted User

After bootstrap, you'll see warnings about untrusted substituters. Fix this:

```bash
# Add to /etc/nix/nix.conf
echo "trusted-users = root @admin" | sudo tee -a /etc/nix/nix.conf

# Restart Nix daemon
sudo launchctl stop org.nixos.nix-daemon
sudo launchctl start org.nixos.nix-daemon

# Verify
grep trusted-users /etc/nix/nix.conf
```

##### 6. Reinstall Neovim Plugins

After Home Manager activates, Neovim plugins need to be reinstalled:

```bash
# Open Neovim
nvim

# In Neovim:
# 1. Visual highlight all plugins in Lazy
# 2. Press 'x' to remove
# 3. Press 'I' to install all

# Or clean and reinstall:
:Lazy clean
:Lazy install
```

### Docker Architecture Setup

```bash
# Remove Intel Docker Desktop via Applications folder or:
# (Old Intel version will be in /Applications)

# Install Docker Desktop for Apple Silicon
# Option 1: Via Homebrew
brew install --cask docker

# Option 2: Download from docker.com

# After installation:
# 1. Open Docker Desktop
# 2. Go to Settings → Advanced
# 3. Enable "Allow the default Docker socket to be used"

# Pull arm64 images explicitly
docker pull --platform linux/arm64 ubuntu:latest

# Set default builder (if using buildx)
docker buildx create --use --platform linux/arm64
```

### Homebrew Dual Installation

Check which packages you have from Intel Homebrew:

```bash
# If /usr/local/bin/brew still exists:
/usr/local/bin/brew list --formula
/usr/local/bin/brew list --cask

# For each package, decide:
# - Is it in Nix? (prefer Nix)
# - Is it macOS-specific? (install via arm64 Homebrew)
# - Is it still needed?

# Install needed packages via Apple Silicon Homebrew
/opt/homebrew/bin/brew install [package]

# After migrating all packages:
# Uninstall all Intel Homebrew packages
/usr/local/bin/brew list --formula | xargs /usr/local/bin/brew uninstall --force --ignore-dependencies
/usr/local/bin/brew list --cask | xargs /usr/local/bin/brew uninstall --cask --force

# Remove Intel Homebrew completely
sudo rm -rf /usr/local/Homebrew
sudo rm -rf /usr/local/Caskroom

# Verify removal
find /usr/local -name "*x86_64*" 2>/dev/null
# Should return nothing
```

### System Keyboard Settings

Manual step that Migration Assistant doesn't preserve:

```bash
# System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys
# - Set Caps Lock to Control
```

---

## Common Issues & Solutions

### Issue: `builtins.currentSystem` Error in Flake

**Symptom:**
```
error: flake 'path:/Users/user/.config/nix' does not provide attribute 'packages.aarch64-darwin.homeConfigurations."MacBook-Pro".activationPackage'
```

**Cause:** Flake hostname doesn't match `scutil --get LocalHostName` or architecture is wrong.

**Solution:**
```bash
# Check your hostname
scutil --get LocalHostName

# Option 1: Use the achhina configuration (architecture auto-detected)
nix run home-manager/master -- switch --flake ~/.config/nix#achhina

# Option 2: Update flake.nix to add your hostname configuration
# See flake.nix line where homeConfigurations are defined
```

### Issue: Nix Wants to Build for Wrong Architecture

**Symptom:**
```
error: Cannot build '/nix/store/....drv'.
       Reason: required system or feature not available
       Required system: 'x86_64-darwin'
       Current system: 'aarch64-darwin'
```

**Cause:** Some package in your configuration is explicitly pinned to x86_64.

**Solution:**
```bash
# Search packages.nix for platform-specific conditionals
cd ~/.config/nix/home-manager/modules
grep -n "x86_64" packages.nix

# Look for patterns like:
# (if isIntelDarwin then oldPkgs.bash-language-server else pkgs.bash-language-server)

# Update or remove x86_64-specific pins
```

### Issue: "File Would Be Clobbered" During Home Manager Activation

**Symptom:**
```
Existing file '/Users/user/.config/nix/nix.conf' would be clobbered
```

**Solution:**
```bash
# Use backup flag
nix run home-manager/master -- switch --flake ~/.config/nix#$(scutil --get LocalHostName) -b backup

# Or manually remove the conflicting file if you're sure
rm ~/.config/nix/nix.conf
```

---

## Development Environment Issues

This section covers issues specific to development tools and environments.

### Neovim Plugin Issues

See [Reinstall Neovim Plugins](#6-reinstall-neovim-plugins) in the Architecture Migration section.

### Pre-commit Hook Failures

**Symptom:**
```bash
gitleaks: cannot execute binary file: Exec format error
```

**Cause:** Migrated x86_64 binaries in cache.

**Solution:**
```bash
rm -rf ~/.cache/pre-commit
# Hooks will reinstall on next commit
```

### markdown-preview.nvim Won't Install

**Symptom:**
```
Vim:E117: Unknown function: mkdp#util#install
```

**Solution:**
```bash
# This plugin requires manual npm install
cd ~/.local/share/nvim/lazy/markdown-preview.nvim
npm install

# Or remove and reinstall through Lazy
# In Neovim: :Lazy clean, then :Lazy install
```

---

## Post-Migration Verification

### Check Architecture

```bash
# System architecture
uname -m
# Should be: arm64 (Apple Silicon) or x86_64 (Intel)

# Check applications
file $(which nvim)
file $(which zsh)
# Should all show arm64 on Apple Silicon

# Check for Intel binaries running under Rosetta
ps aux | grep -i rosetta
# Should be empty or minimal

# List application architectures
system_profiler SPApplicationsDataType | grep -B 1 "Kind:"
# Look for "Kind: Intel" - these should be minimal
```

### Verify Nix Setup

```bash
# Check Nix installation
nix --version
nix-env --version

# Check flakes enabled
nix flake metadata ~/.config/nix

# Check Home Manager generation
home-manager generations
# Should show at least one generation

# Verify packages are correct architecture
file ~/.nix-profile/bin/nvim
file ~/.nix-profile/bin/git
# Should show arm64 on Apple Silicon
```

### Verify Homebrew

```bash
# Check Homebrew location
which brew
# Apple Silicon: /opt/homebrew/bin/brew
# Intel: /usr/local/bin/brew

# Check installed packages architecture
brew list --formula | head -5 | xargs -I {} sh -c 'echo "{}:" && file $(brew --prefix {})/'
```

### Verify Development Tools

```bash
# Test Neovim
nvim --version
nvim +checkhealth

# Test Docker
docker run --rm hello-world
docker run --rm --platform linux/arm64 ubuntu uname -m
# Should output: aarch64

# Test git
git --version
cd ~/.config && git status

# Test pre-commit (if used)
pre-commit --version
```

### Final Checklist

- `sudo` works with Touch ID (if configured)
- All Neovim plugins loaded without errors
- Git operations work (`git status`, `git log`)
- Development shells work (`nix develop`)
- Docker containers run natively (no architecture warnings)
- No Intel/x86_64 applications running via Rosetta
- Homebrew packages are arm64 (if on Apple Silicon)
- All expected CLI tools available and working
- Pre-commit hooks run successfully
- Home Manager switch works: `hm switch`

---

## Troubleshooting

### Enable Verbose Logging

```bash
# Nix operations
nix run home-manager/master --print-build-logs -- switch --flake ~/.config/nix#$(scutil --get LocalHostName) -b backup

# Debug shell startup
zsh -x
```

### Check for Broken Symlinks

```bash
find ~/.config -type l ! -exec test -e {} \; -print
```

### Review Home Manager Activation

```bash
# See what changed
home-manager generations

# Compare to previous generation
nix profile diff-closures

# Roll back if needed
home-manager generations | head -2 | tail -1 | awk '{print $NF}' | xargs home-manager switch --flake
```

### Get Help

If you encounter issues not covered here:

1. Check the [main README](../README.md) for general usage
2. Review [AGENTS.md](../AGENTS.md) for architecture details and system organization
3. Check the [M4 migration diary](../../Documents/new-macbook.md) for a real-world troubleshooting walkthrough
4. Review bootstrap script logs for error details
5. Search Nix/Home Manager documentation

---

## Quick Reference

### Essential Commands Post-Migration

```bash
# Update everything
update

# Rebuild Home Manager
hm switch

# Check for issues
nix flake check ~/.config/nix

# Clean up old generations
nix-collect-garbage -d

# Verify architecture
uname -m && file $(which nvim) && which brew
```

### File Locations

- **Nix config**: `~/.config/nix/flake.nix`
- **Home Manager modules**: `~/.config/nix/home-manager/modules/`
- **Scripts**: `~/.config/scripts/`
- **Packages list**: `~/.config/nix/home-manager/modules/packages.nix`
- **Shell config**: `~/.config/nix/home-manager/modules/shell.nix`
- **PAM config**: `/etc/pam.d/sudo` and `/etc/pam.d/sudo_local`
- **Nix daemon config**: `/etc/nix/nix.conf`
