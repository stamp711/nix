{ self, inputs, ... }:
let
  username = "stamp";
  hostname = "NUC";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClC3VLrypgdZbvJPhufSe6BeWcijyTrnl4JqBs/r566";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDbNYaZnOCmlfKtRpPEq12Ot3iaVjq0AFj7vsB3DcjQ+";
in
{
  imports = [
    ./hardware.nix
    ./vm.nix
    ./tunnel.nix
  ];
  flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
    inherit system;
    nixpkgsConfig.cudaSupport = true;
    modules = [
      self.profiles.nixos.desktop
      self.nixosModules.nuc-hardware
      self.nixosModules.nuc-vm
      self.nixosModules.nuc-tunnel
      self.nixosModules.linux-gaming
      self.nixosModules.tailscale
      (
        { pkgs, ... }:
        {
          my.primaryUser = username;
          networking.hostName = hostname;
          age.rekey.hostPubkey = hostPubkey;

          # Accept GPD's and Surface's host keys for remote build offload
          users.users.${username}.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTQLBSo+0ienoQG9TV4XyNt3vbN60uS10OD4TUDB1an"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH5Pi9art3cmYnc8yuldBqGvtLWWwSK5zjnRKF0l2MyG"
          ];

          # Always-on desktop - disable all sleep states
          systemd.targets.sleep.enable = false;
          systemd.targets.suspend.enable = false;
          systemd.targets.hibernate.enable = false;
          systemd.targets.hybrid-sleep.enable = false;

          specialisation.vm.configuration = {
            system.nixos.tags = [ "vm" ];
            my.win11-vm.enable = true;
          };

          specialisation.lts.configuration = {
            system.nixos.tags = [ "lts" ];
            boot.kernelPackages = pkgs.linuxPackages;
          };
        }
      )
    ];
  };

  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system;
    modules = [
      self.profiles.homeManager.desktop
      self.homeModules.personal
      self.homeModules.linux-gaming
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
