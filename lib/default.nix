{ self, inputs }:
{
  # Create a nixpkgs instance with our standard configuration.
  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = builtins.attrValues self.overlays;
    };

  # Create a home-manager configuration from system, username, and modules.
  mkHome =
    {
      system,
      username,
      modules,
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = self.lib.mkPkgs system;
      extraSpecialArgs = { inherit self inputs; };
      modules = [ { home.username = username; } ] ++ modules;
    };
}
// inputs.utils.lib
// import ./tree.nix { inherit self inputs; }
