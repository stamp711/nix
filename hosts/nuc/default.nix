{ inputs, self, ... }:
let
  username = "stamp";
  hostname = "NUC";
  system = "x86_64-linux";
  nixpkgsConfig = {
    cudaSupport = true;
  };
  # TPM-wrapped identity and recipient, generated on NUC with age-plugin-tpm.
  hostPubkey = ./agenix/key.pub;
  identityPaths = [ "${./agenix/key.tpm}" ];
in
{

  imports = (inputs.import-dir ./. { collect = true; })._all;

  flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
    inherit system nixpkgsConfig;
    modules = [
      self.profiles.nixos.desktop-linux
      self.nixosModules.linux-gaming
      self.nixosModules.personal
      self.nixosModules.nuc

      {
        my.primaryUser = username;
        networking.hostName = hostname;
        age.identityPaths = identityPaths;
        age.rekey.hostPubkey = hostPubkey;
        age.rekey.localStorageDir = self.lib.rekeyDir hostname;
      }

      {
        # Stationary host, so writing back to the NAS is fine here.
        my.smbMounts.nas.shares.Dropbox.rw = true;
        my.smbMounts.nas.shares.Z = { };
      }

      (self.lib.mkHomeModule {
        inherit username;
        modules = [
          self.profiles.homeManager.desktop-linux
          self.homeModules.linux-gaming
          self.homeModules.personal
          self.homeModules.nuc
          {
            my.primaryUser = username;
            age.identityPaths = identityPaths;
            age.rekey.hostPubkey = hostPubkey;
            age.rekey.localStorageDir = self.lib.rekeyDir "${hostname}-${username}";
          }
        ];
      })
    ];
  };

}
