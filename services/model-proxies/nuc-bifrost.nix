{ inputs, ... }:
{
  flake.nixosModules.nuc =
    { config, pkgs, ... }:
    {
      imports = [ "${inputs.bifrost}/nix/modules/bifrost.nix" ];

      services.bifrost = {
        enable = true;
        package = pkgs.my.bifrost;
        host = "0.0.0.0";
        settings = {
          # Default split mode preserves UI-managed providers and keys.
          client.log_retention_days = 30; # Default 0 disables cleanup.
          plugins = [
            {
              name = "telemetry"; # Local Prometheus metrics.
              enabled = false;
            }
          ];
          providers = { }; # TODO:
        };
      };

      systemd.services.bifrost.serviceConfig = {
        StateDirectoryMode = "0700";
        # Retry crashes and catalogue download failures.
        Restart = "on-failure";
        RestartSec = 5;
      };

      my.persistence.directories = [ "/var/lib/private/bifrost" ];

      # Deferred persistence designs:
      # - Bind mount only paths already in /persist. Let services create new paths on
      #   root, then move them to /persist before the next wipe, keeping parent
      #   ownership and permissions. Conflict handling is still to be decided.
      # - Centralize ownership/modes so services do not manage shared parents.
      # - Reuse systemd-tmpfiles directory metadata when preparing persisted parents.
      # Match systemd's private-directory permissions in the backing tree.
      systemd.tmpfiles.rules = [
        "d ${config.my.persistence.path}/var/lib/private 0700 root root -"
      ];
    };
}
