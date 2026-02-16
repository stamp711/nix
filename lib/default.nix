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

  # Create a NixOS system configuration.
  mkNixos =
    {
      system,
      username,
      modules,
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit self inputs; };
      modules = [
        {
          nixpkgs.pkgs = self.lib.mkPkgs system;
          users.users.${username} = {
            isNormalUser = true;
            extraGroups = [
              "wheel"
              "networkmanager"
            ];
          };
        }
      ]
      ++ modules;
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
// import ./import.nix { inherit self inputs; }
// import ./tree.nix { inherit self inputs; }
