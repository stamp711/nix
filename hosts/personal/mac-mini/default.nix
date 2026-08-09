{
  inputs,
  lib,
  self,
  ...
}:
let
  username = "stamp";
  hostname = "Lius-Mac-mini";
  system = "aarch64-darwin";
  systemPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMXmnwlO+kpz+qpq9Y0xRLVdaHbuOr4x81WH7ggNtmsw";
in
{
  imports = (inputs.import-dir ./. { collect = true; })._all;

  flake.darwinConfigurations.${hostname} = self.lib.mkDarwin {
    inherit system;
    rekey = true;
    modules = [
      self.profiles.darwin.minimal
      self.darwinModules.personal
      self.darwinModules.mac-mini

      {
        my.primaryUser = username;
        age.rekey.hostPubkey = systemPubkey;
        age.rekey.localStorageDir = self.lib.rekeyDir hostname;

        services.containerization.enable = true;

        # Those are not in the minimal profile.
        my.maintenance.autoClean = true;
        my.maintenance.autoUpdate = true;
      }

      {
        nix.settings.keep-outputs = true;
        nix.settings.keep-derivations = true;

        # Every check on this system but this host's own, carried in its closure.
        # nix-darwin has no `system.extraDependencies` to do it with.
        system.systemBuilderArgs.extraDependencies = lib.attrValues (
          lib.filterAttrs (name: _: name != "darwin-${hostname}") self.checks.${system}
        );
        system.systemBuilderCommands = ''
          echo -n "$extraDependencies" > $out/extra-dependencies
        '';
      }
    ];
  };

  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system;
    modules = [
      self.profiles.homeManager.minimal
      self.homeModules.personal
      self.homeModules.mac-mini
      {
        my.primaryUser = username;
        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJDMhZj1dTWzY57OW/HlEdBeChcmknv0GWWzfinhdeYu";
        age.rekey.localStorageDir = self.lib.rekeyDir "${hostname}-${username}";

        my.maintenance.autoClean = true;
        my.maintenance.autoUpdate = true;
      }
    ];
  };
}
