{
  self,
  inputs,
  config,
  ...
}:
let
  inherit (inputs.nixpkgs) lib;
  hasRekey = _: cfg: (cfg.config ? age) && (cfg.config.age ? rekey);
  rekeyNixos = lib.filterAttrs hasRekey config.flake.nixosConfigurations;
  rekeyHome = lib.filterAttrs hasRekey config.flake.homeConfigurations;
  rekeyDir = self + "/.rekey";

  extractExpectedFiles =
    configurations:
    lib.concatLists (
      lib.mapAttrsToList (
        _: cfg:
        let
          inherit (cfg.config.age) secrets;
          rekeyed = lib.filterAttrs (_: s: (s.rekeyFile or null) != null) secrets;
        in
        lib.mapAttrsToList (_: s: baseNameOf (toString s.file)) rekeyed
      ) configurations
    );

  expectedFiles = lib.unique (extractExpectedFiles rekeyNixos ++ extractExpectedFiles rekeyHome);

  actualFiles =
    if builtins.pathExists rekeyDir then
      lib.filter (f: lib.hasSuffix ".age" f) (builtins.attrNames (builtins.readDir rekeyDir))
    else
      [ ];

  missing = lib.filter (f: !builtins.elem f actualFiles) expectedFiles;
  orphaned = lib.filter (f: !builtins.elem f expectedFiles) actualFiles;
in
{
  flake.agenix-rekey = inputs.agenix-rekey.configure {
    userFlake = self;
    nixosConfigurations = rekeyNixos;
    homeConfigurations = rekeyHome;
  };

  perSystem =
    { pkgs, ... }:
    {
      checks.agenix-rekey =
        let
          msg =
            lib.optionalString (
              missing != [ ]
            ) "Missing rekeyed secrets: ${builtins.concatStringsSep ", " missing}\n"
            + lib.optionalString (
              orphaned != [ ]
            ) "Orphaned files in agenix-rekey/: ${builtins.concatStringsSep ", " orphaned}\n"
            + "Run 'agenix rekey -a' to fix.";
        in
        assert missing == [ ] && orphaned == [ ] || throw msg;
        pkgs.runCommand "agenix-rekey-check" { } "touch $out";
    };
}
