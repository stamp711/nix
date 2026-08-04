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
        age.rekey.localStorageDir = self.lib.rekeyDir hostname;

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
        age.rekey.localStorageDir = self.lib.rekeyDir "${hostname}-${username}";
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
