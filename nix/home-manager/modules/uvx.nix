{ config, lib, pkgs, ... }:

let
  # List of uv tools to install declaratively
  uvxTools = [
    "pyzotero"
    "claude-code-transcripts"
  ];

  # Python versions to install and manage with uv
  pythonVersions = [
    "3.10"
    "3.11"
    "3.12"
    "3.13"
    "3.14"
    "3.15"
  ];
in
{
  # Install Python versions
  home.activation.installPythonVersions = lib.hm.dag.entryAfter [
    "writeBoundary"
    "linkGeneration"
  ] ''
    if [ -f "${config.home.homeDirectory}/.nix-profile/bin/uv" ]; then
      echo "Installing Python versions: ${builtins.concatStringsSep ", " pythonVersions}..."
      "${config.home.homeDirectory}/.nix-profile/bin/uv" python install ${builtins.concatStringsSep " " pythonVersions}
      echo "Python versions installation complete"
    else
      echo "uv not found, skipping Python installations"
    fi
  '';

  # Install uv tools
  home.activation.installUvTools = lib.hm.dag.entryAfter [
    "installPythonVersions"
  ] ''
    echo "Installing uv tools..."
    mkdir -p "${config.home.homeDirectory}/.local/bin"

    if [ -f "${config.home.homeDirectory}/.nix-profile/bin/uv" ]; then
      for tool in ${builtins.concatStringsSep " " uvxTools}; do
        echo "Installing $tool..."
        "${config.home.homeDirectory}/.nix-profile/bin/uv" tool install "$tool" --force
      done
      echo "uv tools installation complete"
    else
      echo "uv not found, skipping uv tool installs"
    fi
  '';
}
