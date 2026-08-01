# Agent sandboxes: the raft.build daemon and the Hermes agent, one container each.
{ self, ... }:
{
  flake.nixosModules.nuc =
    { config, ... }:
    let
      home = config.users.users.${config.my.primaryUser}.home;
    in
    {
      my.containers = {
        raft = {
          macvlan = "enp4s0";
          hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHDWaJF4rGW5epZONjj0vio3aEMDUKDav+E2Y4Ud0+WM";
          userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9xfQ5oWVVe1AX9PJh0Dy5DJUZ8YMDbwTD9t1/c2K4f";
          # Share the owner's repo stores + agent jj workspaces at identical paths.
          hostDirs = [
            "${home}/code"
            "${home}/agents"
          ];
          nixosModules = [ self.profiles.nixos.headless ];
          homeModules = [
            self.profiles.homeManager.headless
            self.homeModules.raft-computer
            self.homeModules.agent-sandbox
            self.homeModules.github-ratelimit-token
          ];
        };
        hermes = {
          hostDirs = [ "${home}/code" ];
          nixosModules = [
            self.profiles.nixos.headless
            self.nixosModules.hermes-agent
          ];
          homeModules = [ self.profiles.homeManager.headless ];
        };
      };
    };
}
