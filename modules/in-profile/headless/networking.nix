{ lib, ... }:
{
  flake.nixosModules.networking =
    { config, ... }:
    {
      networking = {
        firewall.enable = lib.mkDefault false;
        networkmanager = {
          enable = true;
          wifi.powersave = true;
        };
      };

      my.persistence.directories = lib.optionals config.networking.networkmanager.enable [
        "/etc/NetworkManager/system-connections" # saved connection profiles and credentials
        "/var/lib/NetworkManager" # state, including the secret_key used for stable network identities
      ];

      services.resolved.enable = true; # if not, tailscale will take over system DNS and mishandle surge v4/v6 lookups
    };
}
