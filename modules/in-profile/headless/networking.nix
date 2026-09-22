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

      # Fully declarative network config, no /etc/NetworkManager/system-connection here.
      my.persistence.directories = lib.optionals config.networking.networkmanager.enable [
        "/var/lib/NetworkManager" # secret_key seeds stable-privacy IPv6, cloned MAC, DHCP client id
      ];
    };
}
