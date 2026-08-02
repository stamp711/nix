{ self, ... }:
{
  flake.nixosModules.nuc =
    { config, ... }:
    let
      home = config.users.users.${config.my.primaryUser}.home;
    in
    {
      my.containers = {
        multica = {
          macvlan = "enp4s0";
          hostDirs = [
            "${home}/code"
            "${home}/agents"
          ];
          nixosModules = [ self.profiles.nixos.headless ];
          homeModules = [
            self.profiles.homeManager.headless
            self.homeModules.multica
          ];
        };
      };
    };
}
