let
  managerDefaults = {
    # Keep services with restart policies retrying through extended outages.
    DefaultStartLimitIntervalSec = 0;
    DefaultRestartSec = "10s";
  };
in
{
  flake.nixosModules.core.systemd = {
    settings.Manager = managerDefaults;
    user.settings.Manager = managerDefaults;
  };
}
