{ lib, config, ... }:

let
  # Define separator styles
  separatorStyles = {
    powerline = {
      left = ""; # ple-left_hard_divider
      right = ""; # ple-right_hard_divider
      bar = "│";
    };

    bubbles = {
      left = ""; # ple-left_half_circle_thick
      right = ""; # ple-right_half_circle_thick
      bar = "│";
    };

    thin-bubbles = {
      left = ""; # ple-left_half_circle_thin
      right = ""; # ple-right_half_circle_thin
      bar = "│";
    };

    triangles-lower = {
      left = ""; # lower_right_triangle
      right = ""; # upper_left_triangle
      bar = "";
    };

    triangles-upper = {
      left = ""; # upper_right_triangle
      right = ""; # lower_left_triangle
      bar = "";
    };

    minimal = {
      left = "";
      right = "";
      bar = "│";
    };
  };

  # Define all available themes
  themes = {
    tokyodark = rec {
      # Background shades (darkest to lightest)
      bg0 = "#11121D";
      bg1 = "#1A1B2A";
      bg2 = "#212234";
      bg3 = "#353945";
      bg4 = "#4A5057";
      bg5 = "#282C34";

      # Foreground colors
      fg = "#A0A8CD";

      # Accent colors
      red = "#EE6D85";
      orange = "#F6955B";
      yellow = "#D7A65F";
      green = "#95C561";
      blue = "#7199EE";
      cyan = "#38A89D";
      purple = "#A485DD";
      grey = "#4A5057";

      # Diff colors
      diff_red = "#773440";
      diff_green = "#587738";
      diff_blue = "#2A3A5A";
      diff_add = "#1E2326";
      diff_change = "#262B3D";
      diff_delete = "#281B27";
      diff_text = "#1C4474";

      # UI semantic groupings (similar to Neovim highlight groups)
      ui = {
        # Active/selected elements (like TabLineSel)
        active = {
          fg = bg0;
          bg = red;
        };
        # Inactive elements (like TabLine)
        inactive = {
          fg = fg;
          bg = bg1;
        };
        # Background fill (like TabLineFill)
        fill = {
          fg = fg;
          bg = bg0;
        };
        # Accent/emphasized (used for head/tail sections)
        accent = {
          fg = bg0;
          bg = red;
        };
      };
    };

    catppuccin-mocha = rec {
      # Background shades
      bg0 = "#11111b";
      bg1 = "#181825";
      bg2 = "#1e1e2e";
      bg3 = "#313244";
      bg4 = "#45475a";
      bg5 = "#585b70";

      # Foreground colors
      fg = "#cdd6f4";

      # Accent colors
      red = "#f38ba8";
      orange = "#fab387";
      yellow = "#f9e2af";
      green = "#a6e3a1";
      blue = "#89b4fa";
      cyan = "#94e2d5";
      purple = "#cba6f7";
      grey = "#6c7086";

      # Diff colors
      diff_red = "#3c2d31";
      diff_green = "#2d3c2d";
      diff_blue = "#2d2d3c";
      diff_add = "#1e2326";
      diff_change = "#262B3D";
      diff_delete = "#281B27";
      diff_text = "#1C4474";

      # UI semantic groupings (similar to Neovim highlight groups)
      ui = {
        # Active/selected elements
        active = {
          fg = bg0;
          bg = red;
        };
        # Inactive elements
        inactive = {
          fg = fg;
          bg = bg1;
        };
        # Background fill
        fill = {
          fg = fg;
          bg = bg0;
        };
        # Accent/emphasized
        accent = {
          fg = bg0;
          bg = red;
        };
      };
    };
  };
in
{
  options.theme = {
    name = lib.mkOption {
      type = lib.types.enum (builtins.attrNames themes);
      default = "tokyodark";
      description = "Active theme name. Change this to switch themes globally.";
    };

    separator = lib.mkOption {
      type = lib.types.enum (builtins.attrNames separatorStyles);
      default = "bubbles";
      description = "Active separator style. Change this to switch separator styles globally.";
    };

    colors = lib.mkOption {
      type = lib.types.attrs;
      description = "Currently active theme colors (read-only, determined by theme.name)";
    };

    separators = lib.mkOption {
      type = lib.types.attrs;
      description = "Currently active separator glyphs (read-only, determined by theme.separator)";
    };

    icons = lib.mkOption {
      type = lib.types.attrs;
      default = {
        # System icons
        host = "󰒋";
        cpu = "󰍛";
        memory = "";
        network = "󰖩";

        # Time icons
        clock = "";
        calendar = "󰃭";

        # Battery icons
        battery_charging = "󰂄";
        battery_discharging = "󰁹";
        battery_full = "󰚥";
        battery_unknown = "󰂑";

        # Window/session icons
        window = "";
        session = "";
      };
      description = "Nerd Font icon definitions";
    };
  };

  config = {
    theme.colors = themes.${config.theme.name};
    theme.separators = separatorStyles.${config.theme.separator};
  };
}
