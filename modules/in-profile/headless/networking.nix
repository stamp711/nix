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

      # Fully declarative network config; nothing NetworkManager writes is persisted.
      # NOTE: /var/lib/NetworkManager is not persisted, so IPv6 IID will rotate after reboot.
    };
}
