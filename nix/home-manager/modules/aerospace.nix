{
  pkgs,
  lib,
  ...
}:

{
  programs.aerospace = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    launchd.enable = true;
    settings = {
      after-login-command = [ ];
      # Workaround for AeroSpace bug where default-root-container-layout is not
      # reliably applied on startup. Explicitly set accordion horizontal layout
      # for all workspaces. See: https://github.com/nikitabobko/AeroSpace/issues/568
      after-startup-command = [
        "workspace 1"
        "layout h_accordion"
        "workspace 2"
        "layout h_accordion"
        "workspace 3"
        "layout h_accordion"
        "workspace 4"
        "layout h_accordion"
        "workspace 5"
        "layout h_accordion"
        "workspace 6"
        "layout h_accordion"
        "workspace 7"
        "layout h_accordion"
        "workspace 8"
        "layout h_accordion"
        "workspace 9"
        "layout h_accordion"
        "workspace 10"
        "layout h_accordion"
      ];

      on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

      default-root-container-layout = "accordion";
      default-root-container-orientation = "horizontal";

      gaps = {
        inner = {
          horizontal = 5;
          vertical = 5;
        };
        outer = {
          left = 5;
          bottom = 5;
          top = 5;
          right = 5;
        };
      };

      mode.main.binding = {
        alt-h = "focus --boundaries-action wrap-around-the-workspace left";
        alt-j = "focus --boundaries-action wrap-around-the-workspace down";
        alt-k = "focus --boundaries-action wrap-around-the-workspace up";
        alt-l = "focus --boundaries-action wrap-around-the-workspace right";

        alt-shift-h = [
          "move left"
          "mode main"
        ];
        alt-shift-j = [
          "move down"
          "mode main"
        ];
        alt-shift-k = [
          "move up"
          "mode main"
        ];
        alt-shift-l = [
          "move right"
          "mode main"
        ];

        alt-minus = "resize smart -50";
        alt-equal = "resize smart +50";

        alt-tab = "workspace-back-and-forth";
        alt-shift-tab = "move-workspace-to-monitor --wrap-around next";

        alt-f = "fullscreen";

        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";

        alt-shift-space = "layout floating accordion";

        cmd-h = [ ];
        cmd-alt-h = [ ];

        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-6 = "workspace 6";
        alt-7 = "workspace 7";
        alt-8 = "workspace 8";
        alt-9 = "workspace 9";
        alt-0 = "workspace 10";

        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-6 = "move-node-to-workspace 6";
        alt-shift-7 = "move-node-to-workspace 7";
        alt-shift-8 = "move-node-to-workspace 8";
        alt-shift-9 = "move-node-to-workspace 9";
        alt-shift-0 = "move-node-to-workspace 10";

        alt-shift-c = "reload-config";

        alt-r = "mode resize";
      };

      mode.resize.binding = {
        h = "resize width -50";
        j = "resize height +50";
        k = "resize height -50";
        l = "resize width +50";
        r = [
          "flatten-workspace-tree"
          "mode main"
        ];
        f = [
          "layout floating tiling"
          "mode main"
        ];
        enter = "mode main";
        esc = "mode main";

        alt-shift-h = [
          "join-with left"
          "mode resize"
        ];
        alt-shift-j = [
          "join-with down"
          "mode resize"
        ];
        alt-shift-k = [
          "join-with up"
          "mode resize"
        ];
        alt-shift-l = [
          "join-with right"
          "mode resize"
        ];
      };

      workspace-to-monitor-force-assignment = {
        "4" = 1;
        "3" = 3;
      };

      on-window-detected = [
        {
          "if".app-id = "org.mozilla.firefox";
          check-further-callbacks = true;
          run = [ "move-node-to-workspace 1" ];
        }
        {
          "if".app-id = "com.googlecode.iterm2";
          check-further-callbacks = true;
          run = [ "move-node-to-workspace 2" ];
        }
        {
          "if".app-id = "com.mitchellh.ghostty";
          check-further-callbacks = true;
          run = [ "move-node-to-workspace 2" ];
        }
        {
          "if".app-id = "com.apple.iCal";
          check-further-callbacks = true;
          run = [ "move-node-to-workspace 3" ];
        }
        {
          "if".app-id = "com.apple.mail";
          check-further-callbacks = true;
          run = [ "move-node-to-workspace 3" ];
        }
        {
          "if".app-id = "com.spotify.client";
          check-further-callbacks = true;
          run = [ "move-node-to-workspace 4" ];
        }
        {
          "if".app-id = "si.filips.firefoxpwa.runtime";
          check-further-callbacks = true;
          run = [ "move-node-to-workspace 4" ];
        }
        {
          "if".app-id = "md.obsidian";
          check-further-callbacks = true;
          run = [ "move-node-to-workspace 9" ];
        }
        {
          "if".app-id = "com.hnc.Discord";
          check-further-callbacks = true;
          run = [ "move-node-to-workspace 10" ];
        }
        {
          "if".app-id = "com.apple.MobileSMS";
          check-further-callbacks = true;
          run = [ "move-node-to-workspace 10" ];
        }
        {
          "if".app-id = "net.whatsapp.WhatsApp";
          check-further-callbacks = true;
          run = [ "move-node-to-workspace 10" ];
        }
        {
          "if".app-id = "com.automattic.beeper.desktop";
          check-further-callbacks = true;
          run = [ "move-node-to-workspace 10" ];
        }
      ];
    };
  };
}
