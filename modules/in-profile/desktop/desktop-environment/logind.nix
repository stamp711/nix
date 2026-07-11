{
  flake.nixosModules.desktop-environment = {
    services.logind.settings.Login = {
      HandleLidSwitchExternalPower = "lock";
    };
  };
}
