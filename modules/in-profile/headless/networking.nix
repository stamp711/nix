{ lib, ... }:
{
  flake.nixosModules.networking = {
    networking = {
      firewall.enable = lib.mkDefault false;
      networkmanager = {
        enable = true;
        wifi.powersave = true;
      };
    };

    services.resolved.enable = true; # if not, tailscale will take over system DNS and mishandle surge v4/v6 lookups

    # Fully declarative network config; nothing NetworkManager writes is persisted.
    # NOTE: /var/lib/NetworkManager is not persisted, so IPv6 IID will rotate after reboot.
  };
}
