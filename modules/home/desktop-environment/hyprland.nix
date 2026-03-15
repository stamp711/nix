{
  flake.homeModules.desktop-environment = {
    wayland.windowManager.hyprland = {
      enable = true;
      package = null; # nixosModule handles the binary
      portalPackage = null; # nixosModule handles the portal
      settings = {
        "$mod" = "SUPER";

        monitor = ", preferred, auto, 1";

        bind = [
          # App launchers
          "$mod, RETURN, exec, ghostty"

          # Window management
          "$mod, Q, killactive"
          "$mod, V, togglefloating"
          "$mod, F, fullscreen, 0"

          # Focus
          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"

          # Workspaces
          "$mod, 1, workspace, 1"
          "$mod, 2, workspace, 2"
          "$mod, 3, workspace, 3"
          "$mod, 4, workspace, 4"
          "$mod, 5, workspace, 5"
          "$mod SHIFT, 1, movetoworkspace, 1"
          "$mod SHIFT, 2, movetoworkspace, 2"
          "$mod SHIFT, 3, movetoworkspace, 3"
          "$mod SHIFT, 4, movetoworkspace, 4"
          "$mod SHIFT, 5, movetoworkspace, 5"

          # Pop-up terminal (scratchpad)
          "$mod, GRAVE, togglespecialworkspace, term"
          "$mod SHIFT, GRAVE, movetoworkspacesilent, special:term"
        ];

        animations.enabled = true;
      };
    };
  };
}
