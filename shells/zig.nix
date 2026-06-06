# Per-project zig dev shell. From a project dir:
#   echo 'use flake github:stamp711/nix#zig --impure' > .envrc
# Detects zig from build.zig.zon (minimum_zig_version), else latest master.
# zls is auto-matched to the chosen zig via zig2nix's zls-for.
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

      zig =
        if version == null then
          zigs.zig-master
        else
          let
            attr = "zig-" + lib.replaceStrings [ "." ] [ "_" ] version;
          in
          if zigs ? ${attr} then zigs.${attr} else zigs.zig-master;
    in
    {
      devShells.zig = (inputs.zig2nix.zig-env.${system} { inherit zig; }).mkShell {
        shellHook = ''
          echo "zig $(zig version) · project asked: ${
            if version == null then "unspecified (master)" else version
          }"
        '';
      };
    };
}
