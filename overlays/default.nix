# This file defines overlays
{ inputs, outputs, lib, ... }: {
  # For every flake input, aliases 'pkgs.inputs.${flake}' to
  # 'inputs.${flake}.packages.${pkgs.system}' or
  # 'inputs.${flake}.legacyPackages.${pkgs.system}' or
  flake-inputs = final: _: {
    inputs = builtins.mapAttrs (_: flake:
      (flake.legacyPackages or flake.packages or { }).${final.system} or { })
      inputs;
  };

  # This one brings our custom packages from the 'pkgs' directory
  # additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev:
    {
      # example = prev.example.overrideAttrs (oldAttrs: rec {
      # ...
      # });
    };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      inherit (outputs.nixpkgsConfig) config;
    };
  };

  # Add access to x86_64 packages on Apple Silicon
  apple-silicon-x86_64-packages = self: super:
    lib.optionalAttrs (super.stdenv.system == "aarch64-darwin") {
      pkgs-x86_64 = import inputs.nixpkgs {
        system = "x86_64-darwin";
        inherit (outputs.nixpkgsConfig) config;
      };
    };
}
