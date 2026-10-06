{ self, ... }:
let
  username = "stamp";

  mkSpark =
    hostname:

    self.lib.mkNixos {
      system = "aarch64-linux";

      nixpkgsConfig = {
        cudaSupport = true;
        cudaCapabilities = [ "12.1" ]; # GB10 only
        cudaForwardCompat = false;
      };

      modules = [
        self.profiles.nixos.headless
        self.nixosModules.personal
        self.nixosModules.dgx-spark
        self.nixosModules.${hostname}

        {
          my.primaryUser = username;
          networking.hostName = hostname;
        }

        {
          age.rekey.localStorageDir = self.lib.rekeyDir hostname;
          age.rekey.hostPubkey = ./agenix/${hostname}/key.pub;
          age.identityPaths = [ "${./agenix/${hostname}/key.tpm}" ];
        }

        (self.lib.mkHomeModule {
          class = "nixos";
          inherit username;
          modules = [
            self.profiles.homeManager.headless
            self.homeModules.personal
            self.homeModules.dgx-spark
            {
              my.primaryUser = username;
              age.rekey.localStorageDir = self.lib.rekeyDir "${hostname}-${username}";
              age.rekey.hostPubkey = ./agenix/${hostname}/key.pub;
              age.identityPaths = [ "${./agenix/${hostname}/key.tpm}" ];
            }
          ];
        })

      ];

    };

in
{
  flake.nixosConfigurations.spark-abbc = mkSpark "spark-abbc";
  flake.nixosConfigurations.spark-xxxx = mkSpark "spark-xxxx"; # TODO:
}
