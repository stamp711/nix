{ lib, self, ... }:
let
  hostname = "Lius-Mac-mini";

  builder = {
    host = "lius-mac-mini.boar-char.ts.net";
    # Its own sshd answers the tailnet address, so this is /etc/ssh's key.
    hostPubkey = self.darwinConfigurations.${hostname}.config.age.rekey.hostPubkey;
    # Every Mac's declared host key from agenix-rekey.
    clientPubkeys = lib.remove null (
      lib.mapAttrsToList (_: c: c.config.age.rekey.hostPubkey or null) self.darwinConfigurations
    );
    sshUser = "stamp";
    systems = [ "aarch64-darwin" ];
    supportedFeatures = [ "big-parallel" ]; # nix-darwin does not have defaults for this
    maxJobs = 4;
  };
in
{
  # Every personal machine sees this entry.
  flake.nixosModules.personal.my.nix.build-machine.mac-mini = builder;
  flake.darwinModules.personal.my.nix.build-machine.mac-mini = builder;

  flake.darwinModules.mac-mini = {
    my.nix.build-machine.mac-mini.serve = true;

    nix.settings.keep-outputs = true;
    nix.settings.keep-derivations = true;

    # Every check on this system but this host's own, carried in its closure.
    # nix-darwin has no `system.extraDependencies` to do it with like in nixos.
    system.systemBuilderArgs.extraDependencies = lib.attrValues (
      lib.filterAttrs (name: _: name != "darwin-${hostname}") self.checks.aarch64-darwin
    );
    system.systemBuilderCommands = ''
      echo -n "$extraDependencies" > $out/extra-dependencies
    '';
  };
}
