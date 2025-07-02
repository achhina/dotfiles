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

## 2. How to Make Changes

The preferred method for making changes is to modify the Nix configuration and then apply it.

**Workflow:**

1.  **Identify the correct Nix module:** Locate the relevant file in `/nix/home-manager/modules/` (e.g., `packages.nix` for adding software, `shell.nix` for shell aliases, `git.nix` for Git settings).
2.  **Modify the module:** Make the desired changes to the Nix expressions.
3.  **Apply the changes:** Run the alias `hm` in the shell. This is a shortcut for `home-manager switch --flake ~/.config/nix#achhina`. This command will build and activate the new configuration.
4.  **Verify the changes:** Test the changes to ensure they work as expected.
5.  **Commit the changes:** Commit both the changes to the Nix module and the updated `/nix/flake.lock` file.

**Example: Installing a new package**

1.  Add the package name to the `home.packages` list in `/nix/home-manager/modules/packages.nix`.
2.  Run `hm`.
3.  Verify the package is available by running it in the shell.
4.  Commit the changes.

## 3. Key Configurations & Their Locations

-   **System Packages:** `/nix/home-manager/modules/packages.nix`
-   **Shell Configuration (Zsh):** `/nix/home-manager/modules/shell.nix`
    -   **Aliases:** Defined in the `programs.zsh.shellAliases` section.
    -   **Prompt:** Managed by `programs.starship`.
-   **Git Configuration:** `/nix/home-manager/modules/git.nix`
-   **Neovim Configuration:** `/nvim/`
    -   **Entry Point:** `/nvim/init.lua`
    -   **Plugins:** Managed by `lazy.nvim` in `/nvim/lua/plugins/`.
    -   **Core Settings:** `/nvim/lua/config/` (options, keymaps, etc.).
    -   **Testing Standards:** `/nvim/AGENT.md` (This is a critical document for any Neovim changes).
-   **Aerospace (macOS Tiling WM):** `/nix/home-manager/modules/aerospace.nix` and `/aerospace/`
-   **Tmux:** `/tmux/tmux.conf`

## 4. Interacting with the User

-   **Assume a high level of technical expertise.** The user is comfortable with Nix, Neovim, and the command line.
-   **Be proactive.** When asked to make a change, follow the declarative workflow described above.
-   **Always verify.** After applying changes, always test to ensure they work as expected.
-   **When in doubt, ask.** If you are unsure about how to implement a change, ask for clarification.

## 5. Important Commands & Aliases

-   `hm`: Apply the Home Manager configuration.
-   `update`: Update Nix channels and flakes, and apply the new configuration.
-   `v`: Open Neovim.
-   `t`: Manage Tmux sessions.
-   `l`, `ll`, `lt`: Directory listings with `eza`.
-   `gcd`: Change directory to the root of the current Git repository.

By following these instructions, you will be able to effectively manage and extend this dotfiles repository.
