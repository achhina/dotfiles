# Dotfiles Agent Instructions

This document provides a comprehensive guide for an AI agent to understand and manage this dotfiles repository.

## 1. Core Philosophy & Technology

This repository uses a **declarative approach** to manage a development environment across macOS and Linux systems. The core technologies are:

-   **[Nix](https://nixos.org/):** The foundation for package and environment management.
-   **[Home Manager](https://github.com/nix-community/home-manager):** Manages user-level packages and dotfiles declaratively.
-   **[Neovim](https://neovim.io/):** The primary text editor, configured in Lua.
-   **[Zsh](https://www.zsh.org/):** The shell, configured with Oh My Zsh and Starship.

The main entry point for the entire configuration is `/nix/flake.nix`. All system packages and most application configurations are defined within the Nix modules located in `/nix/home-manager/modules/`.

**Primary Goal:** Maintain a reproducible, cross-platform, and keyboard-driven development environment.

## 2. Dependency Management: A Tiered Approach

Understanding where dependencies come from is critical for updating, using, and debugging this system. The management is layered as follows:

### Tier 1: The Declarative Foundation (Nix + Home Manager)
This is the primary, system-level package manager and the single source of truth for what software is available on the system.

-   **Role:** To declaratively manage and install system-level packages, applications, and even other package managers.
-   **Governing Files:**
    -   `nix/flake.nix`: The entry point that defines all inputs.
    -   `nix/home-manager/modules/packages.nix`: **The master list** of all software managed by Nix.
-   **How to Update:** Run the `update` alias. This will update the Nix flake inputs and apply the new generation.
-   **How to Debug:** If a package is missing or the wrong version, check `nix/home-manager/modules/packages.nix` and the `nix/flake.lock` file.

### Tier 2: Application-Specific Managers
These managers operate within a specific application, handling its internal ecosystem of plugins and extensions. They are installed by Home Manager.

-   **Neovim Plugins (`lazy.nvim`):**
    -   **Role:** Manages all Neovim plugins.
    -   **Governing Files:** `nvim/lua/plugins/` (for definitions) and `nvim/lazy-lock.json` (for version locking).
    -   **How to Update:** Run `:Lazy update` from within Neovim.
    -   **How to Debug:** Use `:Lazy` commands within Neovim. Check for errors during startup.

-   **Zsh Plugins (`oh-my-zsh`):**
    -   **Role:** Manages Zsh plugins.
    -   **Governing File:** `nix/home-manager/modules/shell.nix` (in the `programs.zsh.oh-my-zsh.plugins` section).
    -   **How to Update:** This is managed declaratively by Nix. Updates to the plugins happen when the Nix flake inputs are updated.

### Tier 3: Project-Specific & Tool-Specific Managers
These are tools installed by Home Manager to manage dependencies *within your development projects* or for specific tools.

-   **Python (`uv`/`pip`):**
    -   **Role:** Manages Python packages in project-specific virtual environments.
    -   **Governing Files:** `pyproject.toml` or `requirements.txt` (per-project, not in this repo).
    -   **How to Use:** Managed imperatively on a per-project basis.

-   **Node.js (`pnpm`/`yarn`):**
    -   **Role:** Manages JavaScript/TypeScript dependencies.
    -   **Governing File:** `package.json` (per-project).
    -   **How to Use:** Managed imperatively on a per-project basis.

-   **Git Hooks (`pre-commit`):**
    -   **Role:** Manages linters and formatters used during Git commits.
    -   **Governing File:** `.pre-commit-config.yaml`.
    -   **How to Update:** Run `pre-commit autoupdate`.

## 3. How to Make Changes (The Declarative Workflow)

The preferred method for making changes is to modify the Nix configuration and then apply it.

1.  **Identify the correct Nix module:** Locate the relevant file in `/nix/home-manager/modules/`.
2.  **Modify the module:** Make the desired changes to the Nix expressions.
3.  **Apply the changes:** Run the alias `hm`. This is a shortcut for `home-manager switch --flake ~/.config/nix#achhina`.
4.  **Verify the changes:** Test the changes to ensure they work as expected.
5.  **Commit the changes:** Commit both the changes to the Nix module and the updated `/nix/flake.lock` file.

## 4. Important Commands & Aliases

-   `hm`: Apply the Home Manager configuration.
-   `update`: Update Nix channels and flakes, and apply the new configuration.
-   `v`: Open Neovim.
-   `t`: Manage Tmux sessions.
-   `l`, `ll`, `lt`: Directory listings with `eza`.
-   `gcd`: Change directory to the root of the current Git repository.

By following these instructions, you will be able to effectively manage and extend this dotfiles repository.
