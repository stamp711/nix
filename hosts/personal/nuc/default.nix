{ self, inputs, ... }:
let
  username = "stamp";
  hostname = "NUC";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClC3VLrypgdZbvJPhufSe6BeWcijyTrnl4JqBs/r566";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDbNYaZnOCmlfKtRpPEq12Ot3iaVjq0AFj7vsB3DcjQ+";
in
{

  imports = (inputs.import-dir ./. { collect = true; })._all;

  flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
    inherit system;
    nixpkgsConfig.cudaSupport = true;
    modules = [
      self.profiles.nixos.desktop
      self.nixosModules.linux-gaming
      self.nixosModules.personal
      self.nixosModules.nuc
      {
        my.primaryUser = username;
        networking.hostName = hostname;
        age.rekey.hostPubkey = hostPubkey;

        # Accept GPD's and Surface's host keys for remote build offload.
        users.users.${username}.openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTQLBSo+0ienoQG9TV4XyNt3vbN60uS10OD4TUDB1an" # GPD
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH5Pi9art3cmYnc8yuldBqGvtLWWwSK5zjnRKF0l2MyG" # Surface
        ];

        # Disable all sleep states.
        systemd.targets.sleep.enable = false;
        systemd.targets.suspend.enable = false;
        systemd.targets.hibernate.enable = false;
        systemd.targets.hybrid-sleep.enable = false;

        specialisation.vm.configuration = {
          system.nixos.tags = [ "vm" ];
          my.win11-vm.enable = true;
        };

        # Stationary host, so writing back to the NAS is fine here.
        my.smbMounts.nas.shares.Dropbox.rw = true;
        my.smbMounts.nas.shares.Z = { };

        my.containers.raft = {
          macvlan = "enp4s0";
          hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHDWaJF4rGW5epZONjj0vio3aEMDUKDav+E2Y4Ud0+WM";
          userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9xfQ5oWVVe1AX9PJh0Dy5DJUZ8YMDbwTD9t1/c2K4f";
          # Share the owner's repo stores + agent jj workspaces at identical paths.
          hostDirs = [
            "/home/${username}/code"
            "/home/${username}/agents"
          ];
          nixosModules = [ self.profiles.nixos.headless ];
          homeModules = [
            self.profiles.homeManager.headless
            self.homeModules.raft-computer
            self.homeModules.agent-sandbox
            self.homeModules.github-ratelimit-token
          ];
        };
      }
    ];
  };

  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system;
    modules = [
      self.profiles.homeManager.desktop
      self.homeModules.linux-gaming
      self.homeModules.personal
      {
        my.primaryUser = username;
        age.rekey.hostPubkey = userPubkey;
      }
    ];
  };

  flake.deploy.nodes.${hostname} = {
    hostname = "NUC.home";
    remoteBuild = true;
    profiles = {
      home-manager = {
        user = username;
        path =
          inputs.deploy-rs.lib.${system}.activate.home-manager
            self.homeConfigurations."${username}@${hostname}";
      };
      system = {
        user = "root";
        path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${hostname};
      };
    };
  };

}
