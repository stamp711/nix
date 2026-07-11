{
  flake.nixosModules.cli-programs =
    { pkgs, ... }:
    {
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          stdenv.cc.cc.lib
          zlib
          openssl # useful for arbitrary cargo projects
        ];
      };
    };

  flake.homeModules.cli-programs =
    { lib, pkgs, ... }:
    let
      # rustup without the patch that rewrites ELF interpreters of downloaded toolchains
      rustup-nix-ld =
        let
          patchName = "0001-dynamically-patchelf-binaries.patch";
          expectedDrops = if pkgs.stdenv.hostPlatform.isLinux then 1 else 0;
        in
        pkgs.rustup.overrideAttrs (
          old:
          let
            kept = builtins.filter (p: !(lib.hasSuffix patchName (toString p))) old.patches;
            dropped = builtins.length old.patches - builtins.length kept;
          in
          assert lib.assertMsg (dropped == expectedDrops) ''
            rustup-nix-ld: expected to drop ${toString expectedDrops} patch(es) named "${patchName}",
            actually dropped ${toString dropped}. nixpkgs has likely restructured
            pkgs/development/tools/rust/rustup/default.nix; review the override.
          '';
          {
            patches = kept;
            doCheck = false;
          }
        );
    in
    {
      home.packages = with pkgs; [
        rustup-nix-ld
        stdenv.cc
      ];
      home.sessionPath = [ "$HOME/.cargo/bin" ];
    };
}
