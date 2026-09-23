# Atuin sync: encryption key from agenix, daemon off.
# NOTE: still needs per host login session.
# WARN: needs to rekey or nuke ~/.local/share/atuin/records.db* before first login.
{ self, ... }:
{
  flake.homeModules.personal =
    { config, lib, ... }:
    let
      key = self.lib.mkAgeSecret config { rekeyFile = ./key.age; };
    in
    lib.mkIf config.programs.atuin.enable {
      age.secrets = key.ageSecret;
      programs.atuin.settings.key_path = key.path;
      programs.atuin.daemon.enable = false;
    };
}
