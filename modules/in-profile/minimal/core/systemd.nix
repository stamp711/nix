{
  flake.nixosModules.core.systemd.settings.Manager = {
    # Keep services with restart policies retrying through extended outages.
    DefaultStartLimitIntervalSec = 0;
    DefaultRestartSec = "10s";
  };
}
