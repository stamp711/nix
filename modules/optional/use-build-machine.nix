# Offload builds to NUC
{ lib, self, ... }:
let
  hostName = "nuc.boar-char.ts.net";
  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXPqL5kmB12FkY38iEo57HrkyadcFxpBvKqWqYRE7zl";
in
{
  flake.nixosModules.use-build-machine =
    { config, ... }:
    {
      nix.distributedBuilds = true;
      nix.settings.builders-use-substitutes = true;
      nix.buildMachines = [
        {
          inherit hostName;
          sshUser = "stamp";
          sshKey =
            (lib.findFirst (k: k.type == "ed25519")
              (throw "use-build-machine: no ed25519 host key to authenticate with")
              config.services.openssh.hostKeys
            ).path;
          systems = [ "x86_64-linux" ];
          protocol = "ssh-ng";
          maxJobs = 8;
          supportedFeatures = self.nixosConfigurations.NUC.config.nix.settings.system-features;
        }
      ];
      programs.ssh.knownHosts.${hostName} = { inherit publicKey; };
    };
}
