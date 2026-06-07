# Per-project zig dev shell. From a project dir:
#   echo 'use flake github:stamp711/nix#zig --impure' > .envrc
# Detects zig from build.zig.zon (minimum_zig_version), else nightly.
# Nightly path: zig-flake nightly + zls built from same zig-flake pin (follows).
# Tagged path: zig2nix zig + version-matched zig2nix zls.
{ inputs, ... }:
{
  perSystem =
    { lib, system, ... }:
    let
      zigs = inputs.zig2nix.packages.${system};

      cwd = builtins.getEnv "PWD";
      zon = "${cwd}/build.zig.zon";

      # cwd == "" under pure eval (e.g. nix flake check) -> skip detection
      version =
        if cwd == "" || !builtins.pathExists zon then
          null
        else
          let
            hit = lib.findFirst (l: lib.hasInfix "minimum_zig_version" l) null (
              lib.splitString "\n" (builtins.readFile zon)
            );
            m = if hit == null then null else builtins.match ".*\"([0-9][^\"]*)\".*" hit;
          in
          if m == null then null else builtins.head m;
      v = lib.replaceStrings [ "." ] [ "_" ] version;

      useNightly = version == null || !(zigs ? "zig-${v}");

      zig =
        if useNightly then
          # hook stub: zig-env's mkShell dereferences zig.hook, zig-flake pkgs lack it
          inputs.zig-flake.packages.${system}.nightly // { hook = null; }
        else
          zigs."zig-${v}";

      # exact zls, else highest same-minor (pre-1.0 compat boundary), else fail loud
      zls =
        if useNightly then
          inputs.zls.packages.${system}.zls
        else
          zigs."zls-${v}" or (
            let
              minor = lib.concatStringsSep "_" (lib.take 2 (lib.splitString "_" v));
              sameMinor = lib.filter (n: lib.hasPrefix "zls-${minor}_" n) (lib.attrNames zigs);
            in
            if sameMinor != [ ] then
              zigs.${lib.last (lib.naturalSort sameMinor)}
            else
              throw "no zls for zig ${version}"
          );
    in
    {
      devShells.zig = (inputs.zig2nix.zig-env.${system} { inherit zig zls; }).mkShell {
        shellHook = ''
          echo "zig $(zig version) · project asked: ${
            if version == null then "unspecified" else version
          }${lib.optionalString useNightly " → nightly"}"
        '';
      };
    };
}
