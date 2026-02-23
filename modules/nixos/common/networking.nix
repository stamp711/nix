{
  description = "NetworkManager with wifi powersave";

  module =
    { lib, ... }:
    {
      networking = {
        firewall.enable = lib.mkDefault false;
        networkmanager = {
          enable = true;
          wifi.powersave = true;
        };
      };
    };
}
