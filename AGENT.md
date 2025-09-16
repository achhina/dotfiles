# Dotfiles Agent Instructions

This document provides a comprehensive guide for an AI agent to understand and manage this dotfiles repository.

## 1. Guiding Principles & Architecture

This repository treats the entire development environment as a unified, version-controlled software project. Its architecture is guided by a few core principles:

- **Total Declarative Control.** The environment is defined as code. **Nix and Home Manager** serve as the single source of truth, ensuring that the system is **bit-for-bit reproducible**. The `flake.nix` is the main entry point, and the goal is to eliminate all manual setup.

- **Structured by Function.** The configuration is organized into **logical tiers** based on their function and stability, not just by tool name. This separates the foundational **Declarative Core** (`nix/`) from the frequently-tweaked **Interactive Environment** (`nvim/`). When looking to update a configuration ALWAYS check `nix/` FIRST for any declarative configuration before checking the application configuration directories and files.

- **Engineered for Portability.** The use of Nix, conditional logic (`pkgs.stdenv.isDarwin`), and a focus on cross-platform tools ensures the environment is **portable across macOS and Linux** on different architectures.

## 2. Dependency Management: A Tiered Approach

Understanding where dependencies come from is critical for updating, using, and debugging this system. The management is layered as follows:

### Tier 1: The Declarative Foundation (Nix + Home Manager)
This is the primary, system-level package manager and the single source of truth for what software is available on the system.

- **Role:** To declaratively manage and install system-level packages, applications, and even other package managers.
- **Governing Files:**
  - `nix/flake.nix`: The entry point that defines all inputs.
  - `nix/home-manager/modules/packages.nix`: **The master list** of all software managed by Nix.
- **How to Update:**
    - Run the `update` alias. This will update the Nix flake inputs and apply the new generation.
    - Run the `hm switch` OR `home-manager switch` after EVERY change to a nix module.
- **How to Debug:** If a package is missing or the wrong version, check `nix/home-manager/modules/packages.nix` and the `nix/flake.lock` file.

### Tier 2: Application-Specific Managers
These managers operate within a specific application, handling its internal ecosystem of plugins and extensions. They are installed by Home Manager.

- **Neovim Plugins (`lazy.nvim`):**
  - **Role:** Manages all Neovim plugins.
  - **Governing Files:** `nvim/lua/plugins/` (for definitions) and `nvim/lazy-lock.json` (for version locking).
  - **How to Update:** Run `:Lazy update` from within Neovim.
  - **How to Debug:** Use `:Lazy` commands within Neovim. Check for errors during startup.

- **Zsh Plugins (`oh-my-zsh`):**
  - **Role:** Manages Zsh plugins.
  - **Governing File:** `nix/home-manager/modules/shell.nix` (in the `programs.zsh.oh-my-zsh.plugins` section).
  - **How to Update:** This is managed declaratively by Nix. Updates to the plugins happen when the Nix flake inputs are updated.

## 3. The Change Workflow: A Strict Protocol

All modifications to this repository must follow this protocol to ensure changes are small, verifiable, and atomic.

**1. Plan the Atomic Change**
- **Define a single, clear goal.** What is the one thing that should be different after this change?
- **Identify the responsible component.** Using Section 2, determine which management tier (Nix, Neovim's `lazy.nvim`, etc.) controls this component.

**2. Establish a Verifiable Baseline**
- **Capture the "before" state.** Before making any edits, run commands to prove the current state.
- *Example:* If adding a package, prove it's not installed (`command -v my-package` should fail). For Neovim, follow the testing standards in `nvim/AGENT.md`.

**3. Execute the Idempotent Change**
- **Modify only the necessary files** for the single planned change.
- **Apply the change** using the correct tier-specific command (`hm`, `:Lazy sync`, etc.). An idempotent change should be safely repeatable.

**4. Verify the Outcome**
- **Capture the "after" state.** Run the *exact same commands* from Step 2.
- **Confirm success.** The output must match the goal defined in Step 1.
- **Check for regressions.** Ensure no other parts of the system were negatively affected.

**5. Commit Atomically**
- **Commit the single, verified change.** The commit must be self-contained.
- **Write a clear commit message.** Describe the *why* behind the change, not just the *what*.
- *Example:* A Nix package addition must include the change to `packages.nix` and the resulting `flake.lock` in the same commit.

This protocol is mandatory for all changes, from adding a shell alias to updating a Neovim plugin.

## 4. Environment Inspection

This setup uses **Nix flakes exclusively** - no channels. Key inspection commands:

- **View package changes:** `nix profile diff-closures` (shows Home Manager changes via user profile symlinks)
- **Search packages:** `nix search nixpkgs` (global registry, latest unstable) vs `nix search .#` (your pinned versions)
- **Profile types:** User profiles (imperative `nix profile install`) vs Home Manager generations (declarative, this setup)

## 5. Home Manager Option Discovery

When working with Home Manager modules, discovering available configuration options can be challenging with flakes. Here are the proven methods, ranked by effectiveness:

### Method 1: Local Manual (Most Reliable)
```bash
man home-configuration.nix
# Press '/' and search for module name (e.g., "jankyborders")
# Shows all options with types, defaults, and examples
```

This is the most practical approach - the manual is always up-to-date with your Home Manager version and contains every option with documentation.

### Method 2: GitHub Source Code (Most Detailed)
For complex modules or when you need implementation details:
```bash
# Navigate to: https://github.com/nix-community/home-manager/tree/master/modules/
# Find the module file (e.g., services/jankyborders.nix)
```

### Method 3: grep Search (Quick Reference)
```bash
man home-configuration.nix | grep -C 10 "modulename"
```

### What Doesn't Work with Flakes:
- `home-manager option` commands (flake configurations not supported)
- `apropos` (searches system man pages, not Home Manager options)
- Auto-generated documentation builds (not exposed by default in flakes)

### Best Practice:
Start with `man home-configuration.nix` and search. Only resort to GitHub source when you need to understand implementation details or see complex examples.
