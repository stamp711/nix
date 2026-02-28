{ self, inputs }:
{
  nixosConfigurations ? { },
  homeConfigurations ? { },
}:
let
  inherit (inputs.nixpkgs) lib;
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

  expectedFiles = lib.unique (
    extractExpectedFiles nixosConfigurations ++ extractExpectedFiles homeConfigurations
  );

  actualFiles =
    if builtins.pathExists rekeyDir then
      lib.filter (f: lib.hasSuffix ".age" f) (builtins.attrNames (builtins.readDir rekeyDir))
    else
      [ ];
in
{
  missing = lib.filter (f: !builtins.elem f actualFiles) expectedFiles;
  orphaned = lib.filter (f: !builtins.elem f expectedFiles) actualFiles;
}
