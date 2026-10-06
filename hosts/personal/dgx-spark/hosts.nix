{ self, ... }:
let
  username = "stamp";

  dummyPubkey = self.nixosConfigurations.spark-xxxx.options.age.rekey.hostPubkey.default;

  pubKeys = {
    spark-abbc = {
      host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKvc/EVZSLvKJSJPNYKT2+CovXPGhJpyAbDuTLVhJrG0";
      user = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAp+lIKku2LR90lnmhvV4aPHCfwDcvGMg0fQa9dW8lGl";
    };
    spark-xxxx = {
      # TODO: replace the dummy keys.
      host = dummyPubkey;
      user = dummyPubkey;
    };
  };

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
          age.rekey.hostPubkey = pubKeys.${hostname}.host;
          age.rekey.localStorageDir = self.lib.rekeyDir hostname;
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
              age.rekey.hostPubkey = pubKeys.${hostname}.user;
              age.rekey.localStorageDir = self.lib.rekeyDir "${hostname}-${username}";
            }
          ];
        })

      ];

    };

in
{
  flake.nixosConfigurations.spark-abbc = mkSpark "spark-abbc";
  flake.nixosConfigurations.spark-xxxx = mkSpark "spark-xxxx"; # TODO: hostname.
}
