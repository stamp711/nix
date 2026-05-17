{
  flake.nixosModules.desktop-environment = {
    services.desktopManager.cosmic.enable = true;
  };
}
