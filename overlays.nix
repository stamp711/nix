{ inputs, ... }:
{
  # For every flake input, aliases 'pkgs.inputs.${flake}' to
  # 'inputs.${flake}.packages.${pkgs.system}' or
  # 'inputs.${flake}.legacyPackages.${pkgs.system}'
  flake-inputs = final: _: {
    inputs = builtins.mapAttrs (
      _: flake: (flake.legacyPackages or flake.packages or { }).${final.system} or { }
    ) inputs;
  };

  # Custom modifications to packages
  modifications = _: _: {
    # Example: override a package
    # somePackage = prev.somePackage.overrideAttrs (oldAttrs: {
    #   version = "custom";
    # });
  };

  # Add access to x86_64 packages on Apple Silicon
  apple-silicon =
    _: prev:
    if prev.stdenv.system == "aarch64-darwin" then
      {
        pkgs-intel = import inputs.nixpkgs {
          system = "x86_64-darwin";
          config.allowUnfree = true;
        };
      }
    else
      { };
}
