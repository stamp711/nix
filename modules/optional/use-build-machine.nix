# Offload builds to NUC
{ self, ... }: {
  flake.nixosModules.use-build-machine = {
    nix.distributedBuilds = true;
    nix.settings.builders-use-substitutes = true;
    nix.buildMachines = [
      {
        hostName = "NUC";
        sshUser = "stamp";
        sshKey = "/persist/etc/ssh/ssh_host_ed25519_key";
        systems = [ "x86_64-linux" ];
        protocol = "ssh-ng";
        maxJobs = 8;
        supportedFeatures = self.nixosConfigurations.NUC.config.nix.settings.system-features;
      }
    ];
    programs.ssh.knownHosts."NUC".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClC3VLrypgdZbvJPhufSe6BeWcijyTrnl4JqBs/r566";
  };
}
