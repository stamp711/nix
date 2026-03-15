{ self, inputs, ... }:
let
  username = "stamp";
  hostname = "NUC";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClC3VLrypgdZbvJPhufSe6BeWcijyTrnl4JqBs/r566";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDbNYaZnOCmlfKtRpPEq12Ot3iaVjq0AFj7vsB3DcjQ+";
in
{
  flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
    inherit system;
    modules = [
      self.profiles.nixos.desktop
      ./hardware.nix
      ./vm.nix
      {
        my.primaryUser = username;
        networking.hostName = hostname;
        age.rekey.hostPubkey = hostPubkey;

        # Always-on desktop - disable all sleep states
        systemd.targets.sleep.enable = false;
        systemd.targets.suspend.enable = false;
        systemd.targets.hibernate.enable = false;
        systemd.targets.hybrid-sleep.enable = false;
        services.displayManager.gdm.autoSuspend = false;

        specialisation.desktop.configuration = {
          system.nixos.tags = [ "desktop" ];
          my.win11-vm.enable = false;
        };

        specialisation.gaming.configuration = {
          system.nixos.tags = [ "steam" ];
          my.win11-vm.enable = false;
          programs.gamemode.enable = true;
          services.xserver.videoDrivers = [ "nvidia" ];
          hardware.nvidia.modesetting.enable = true;
          hardware.nvidia.open = true;
          services.displayManager.autoLogin.enable = true;
          services.displayManager.autoLogin.user = username;
          services.displayManager.defaultSession = "steam";
        };
      }
    ];
  };

  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system;
    modules = [
      self.profiles.homeManager.desktop
      {
        my.primaryUser = username;
        age.rekey.hostPubkey = userPubkey;
        my.ssh.secretConfigFiles = [ ../ssh-hosts.conf.age ];
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
