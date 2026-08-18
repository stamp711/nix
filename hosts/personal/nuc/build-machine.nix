{ self, ... }:
let
  builder = {
    host = "nuc.boar-char.ts.net";
    # Tailscale SSH answers port 22 on the tailnet, so this is its key, not /etc/ssh's.
    # It also authenticates by tailnet identity, which is why no client key is listed.
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXPqL5kmB12FkY38iEo57HrkyadcFxpBvKqWqYRE7zl";
    sshUser = "stamp";
    systems = [ "x86_64-linux" ];
    supportedFeatures = self.nixosConfigurations.NUC.config.nix.settings.system-features;
    maxJobs = 8;
  };
in
{
  # Every personal machine sees this entry.
  flake.nixosModules.personal.my.nix.build-machine.nuc = builder;
  flake.darwinModules.personal.my.nix.build-machine.nuc = builder;

  flake.nixosModules.nuc.my.nix.build-machine.nuc.serve = true;
}
