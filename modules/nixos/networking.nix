{
  flake.nixosModules.networking =
    { lib, config, ... }:
    {
      networking = {
        firewall.enable = lib.mkDefault false;
        networkmanager = {
          enable = true;
          wifi.powersave = true;
        };
      };
      users.users.${config.my.primaryUser}.extraGroups = [ "networkmanager" ];
    };
}
