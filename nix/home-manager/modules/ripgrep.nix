{ config, pkgs, ... }:

{
  programs.ripgrep = {
    enable = true;

    arguments = [
      # Smart case sensitivity (case-insensitive unless uppercase used)
      "--smart-case"

      # Follow symbolic links
      "--follow"



      # Compact output with no heading and filename on each line
      "--no-heading"

      # Show colors in output
      "--color=always"

      # Enable clickable hyperlinks
      "--hyperlink-format=default"

      # Custom colors matching terminal theme
      "--colors=line:fg:yellow"
      "--colors=line:style:bold"
      "--colors=path:fg:cyan"
      "--colors=path:style:bold"
      "--colors=match:fg:red"
      "--colors=match:style:bold"

      # Performance and behavior
      "--max-columns=150"
      "--max-columns-preview"

      # Include hidden files but respect gitignore
      "--hidden"

      # Additional ignore patterns
      "--glob=!.git/*"
      "--glob=!node_modules/*"
      "--glob=!.DS_Store"
      "--glob=!*.min.js"
      "--glob=!*.min.css"
      "--glob=!yarn.lock"
      "--glob=!package-lock.json"
      "--glob=!.next/*"
      "--glob=!dist/*"
      "--glob=!build/*"
      "--glob=!target/*"
      "--glob=!*.log"
    ];
  };
}
