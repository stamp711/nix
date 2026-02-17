{ self, inputs }:
nixosConfigurations:
let
  inherit (inputs.nixpkgs) lib;
  rekeyDir = self + "/.rekey";

  expectedFiles = lib.unique (
    lib.concatLists (
      lib.mapAttrsToList (
        _: cfg:
        let
          inherit (cfg.config.age) secrets;
          rekeyed = lib.filterAttrs (_: s: (s.rekeyFile or null) != null) secrets;
        in
        lib.mapAttrsToList (_: s: baseNameOf (toString s.file)) rekeyed
      ) nixosConfigurations
    )
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
