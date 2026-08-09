{
  flake.nixosModules.networking =
    { config, lib, ... }:
    {
      networking = {
        firewall.enable = lib.mkDefault false;
        networkmanager = {
          enable = true;
          wifi.powersave = true;
        };
      };

      my.persistence.directories = lib.optionals config.networking.networkmanager.enable [
        "/etc/NetworkManager/system-connections" # credentials
        "/var/lib/NetworkManager" # secret_key for the credentials
      ];
    };
}
