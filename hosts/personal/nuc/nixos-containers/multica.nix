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
          hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/jMf11vuK96PYpriaiDrMzK84dZLmyrXcOpTKKdnDd";
          userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIALLBecHQg9j3ORcEWlEeySjL+ZMMUGBbK3M2VipnTJi";
          hostDirs = [ "${home}/code" ];
          nixosModules = [ self.profiles.nixos.headless ];
          homeModules = [
            self.profiles.homeManager.headless
            self.homeModules.agent-sandbox
            self.homeModules.github-ratelimit-token
            self.homeModules.multica
          ];
        };
      };
    };
}
