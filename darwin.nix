{ pkgs, lib, ... }: {
  programs.zsh.enable = true;
  system.stateVersion = 4;

  users.users.stamp = { home = "/Users/stamp"; };

  services.nix-daemon.enable = true;
  nix.settings = {
    auto-optimise-store = true;
    trusted-users = [ "@admin" ];
  };
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '' + lib.optionalString (pkgs.system == "aarch64-darwin") ''
    extra-platforms = x86_64-darwin aarch64-darwin
  '';

  services.yabai.enable = true;
  services.yabai.enableScriptingAddition = true;
  services.yabai.config = {
    mouse_follows_focus = "off";
    focus_follows_mouse = "off";
    window_origin_display = "default";
    window_placement = "second_child";
    window_zoom_persist = "on";
    window_topmost = "off";
    window_shadow = "off";
    window_animation_duration = 0.0;
    window_animation_frame_rate = 120;
    window_opacity_duration = 0.0;
    active_window_opacity = 1.0;
    normal_window_opacity = 0.9;
    window_opacity = "off";
    insert_feedback_color = "0xffd75f5f";
    active_window_border_color = "0xff775759";
    normal_window_border_color = "0xff555555";
    window_border_width = 4;
    window_border_radius = 12;
    window_border_blur = "off";
    window_border_hidpi = "on";
    window_border = "off";
    split_ratio = 0.5;
    split_type = "auto";
    auto_balance = "off";
    top_padding = 0;
    bottom_padding = 0;
    left_padding = 0;
    right_padding = 0;
    window_gap = 6;
    # layout = "bsp";
    mouse_modifier = "fn";
    mouse_action1 = "move";
    mouse_action2 = "resize";
    mouse_drop_action = "swap";
  };
  services.yabai.extraConfig = ''
    # Space 3 is for development
    yabai -m config --space 3 layout bsp
    yabai -m rule --add app='System Settings' manage=off
    yabai -m rule --add app='OrbStack' manage=off
    yabai -m rule --add app='Surge' manage=off
    # TODO: this two lines should be at the top of the configuration file.
    yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
    sudo yabai --load-sa
  '';
}
