{ inputs, self, ... }:
let
  username = "stamp";
  hostname = "NUC";
  system = "x86_64-linux";
  nixpkgsConfig = {
    cudaSupport = true;
  };
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClC3VLrypgdZbvJPhufSe6BeWcijyTrnl4JqBs/r566";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDbNYaZnOCmlfKtRpPEq12Ot3iaVjq0AFj7vsB3DcjQ+";
in
{

  imports = (inputs.import-dir ./. { collect = true; })._all;

  flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
    inherit system nixpkgsConfig;
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
      }

      {
        # Stationary host, so writing back to the NAS is fine here.
        my.smbMounts.nas.shares.Dropbox.rw = true;
        my.smbMounts.nas.shares.Z = { };
      }

      (self.lib.mkHomeModule {
        class = "nixos";
        inherit username;
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
      })
    ];
  };

}
