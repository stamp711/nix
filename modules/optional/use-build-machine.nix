# Offload builds to NUC
{ self, ... }:
let
  hostName = "nuc.boar-char.ts.net";
  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXPqL5kmB12FkY38iEo57HrkyadcFxpBvKqWqYRE7zl";
in
{
  flake.nixosModules.use-build-machine = {
    nix.distributedBuilds = true;
    nix.settings.builders-use-substitutes = true;
    nix.buildMachines = [
      {
        inherit hostName;
        sshUser = "stamp";
        sshKey = "/persist/etc/ssh/ssh_host_ed25519_key";
        systems = [ "x86_64-linux" ];
        protocol = "ssh-ng";
        maxJobs = 8;
        supportedFeatures = self.nixosConfigurations.NUC.config.nix.settings.system-features;
      }
    ];
    programs.ssh.knownHosts.${hostName} = { inherit publicKey; };
  };
}
