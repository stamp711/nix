{
  flake.nixosModules.desktop-linux = {
    services.logind.settings.Login = {
      HandlePowerKey = "suspend-then-hibernate";
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchExternalPower = "lock";
    };

    systemd.sleep.settings.Sleep.HibernateDelaySec = "2h";
  };
}
