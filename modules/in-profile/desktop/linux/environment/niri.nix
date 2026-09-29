{
  flake.nixosModules.desktop-linux = {
    programs.niri.enable = true;
  };

  flake.homeModules.desktop-linux = {
    wayland.windowManager.niri = {
      # NixOS already manages the session and portals.
      enable = true;
      systemd.enable = false;
      portalPackage = null;

      enableDefaultConfig = true;
      settings = {
        prefer-no-csd = { };
      };
    };
  };
}
