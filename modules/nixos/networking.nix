{
  flake.nixosModules.networking =
    { lib, ... }:
    {
      networking = {
        firewall.enable = lib.mkDefault false;
        networkmanager = {
          enable = true;
          wifi.powersave = true;
        };
      };

      # NM state must survive @root wipes, secret_key in /var/lib/NetworkManager
      # encrypts the credentials stored under /etc/NetworkManager/system-connections,
      # so both must move together.
      my.persistence.directories = [
        "/etc/NetworkManager/system-connections"
        "/var/lib/NetworkManager"
      ];
    };
}
