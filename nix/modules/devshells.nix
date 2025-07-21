{ pkgs }:

{
  # Default shell with common tools
  default = pkgs.mkShell {
    buildInputs = with pkgs; [
      git
      gh
      curl
      jq
      ripgrep
      fd
      fzf
    ];
    shellHook = ''
      echo "🚀 Development environment ready!"
      echo "Available tools: git, gh, curl, jq, ripgrep, fd, fzf"
    '';
  };

  # Python development shell
  python = pkgs.mkShell {
    buildInputs = with pkgs; [
      python3
      python3Packages.pip
      python3Packages.virtualenv
      uv
      pyright
      ruff
      python3Packages.black
      python3Packages.ipython
      python3Packages.pytest
    ];
    shellHook = ''
      echo "🐍 Python development environment"
      echo "Python $(python --version)"
      echo "Tools: uv, pyright, ruff, black, ipython, pytest"
    '';
  };

  # Node.js development shell
  node = pkgs.mkShell {
    buildInputs = with pkgs; [
      nodejs
      pnpm
      yarn
      typescript
      typescript-language-server
      nodePackages.eslint
      nodePackages.prettier
    ];
    shellHook = ''
      echo "📦 Node.js development environment"
      echo "Node $(node --version)"
      echo "Tools: pnpm, yarn, typescript, eslint, prettier"
    '';
  };

  # Go development shell
  go = pkgs.mkShell {
    buildInputs = with pkgs; [
      go
      gopls
      golint
      delve
      gotools
    ];
    shellHook = ''
      echo "🔵 Go development environment"
      echo "Go $(go version | cut -d' ' -f3)"
      echo "Tools: gopls, golint, delve, gotools"
    '';
  };

  # Rust development shell
  rust = pkgs.mkShell {
    buildInputs = with pkgs; [
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
    ];
    shellHook = ''
      echo "🦀 Rust development environment"
      echo "Rust $(rustc --version)"
      echo "Tools: cargo, rustfmt, clippy, rust-analyzer"
    '';
  };

  # Data science shell
  datascience = pkgs.mkShell {
    buildInputs = with pkgs; [
      python3
      python3Packages.jupyter
      python3Packages.pandas
      python3Packages.numpy
      python3Packages.matplotlib
      python3Packages.seaborn
      python3Packages.scikit-learn
      python3Packages.ipython
      uv
      pyright
    ];
    shellHook = ''
      echo "📊 Data Science environment"
      echo "Python $(python --version)"
      echo "Tools: jupyter, pandas, numpy, matplotlib, scikit-learn"
      echo "Start with: jupyter lab"
    '';
  };
}
