{
  flake.nixosModules.desktop-linux = {
    services.logind.settings.Login = {
      HandleLidSwitchExternalPower = "lock";
    };
  };
}
