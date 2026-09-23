{ inputs, self, ... }:
let
  username = "stamp";
  hostname = "spark-abbc";
  system = "aarch64-linux";
  nixpkgsConfig = {
    cudaSupport = true;
    cudaCapabilities = [ "12.1" ]; # GB10 only
    cudaForwardCompat = false;
  };
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKvc/EVZSLvKJSJPNYKT2+CovXPGhJpyAbDuTLVhJrG0";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAp+lIKku2LR90lnmhvV4aPHCfwDcvGMg0fQa9dW8lGl";
in
{
  imports = (inputs.import-dir ./. { collect = true; })._all;

  flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
    inherit system nixpkgsConfig;
    modules = [
      self.profiles.nixos.headless
      self.nixosModules.personal
      self.nixosModules.dgx-spark
      {
        my.primaryUser = username;
        networking.hostName = hostname;
        age.rekey.hostPubkey = hostPubkey;
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
            age.rekey.hostPubkey = userPubkey;
            age.rekey.localStorageDir = self.lib.rekeyDir "${hostname}-${username}";
          }
        ];
      })
    ];
  };
}
