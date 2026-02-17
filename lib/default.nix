{ self, inputs }:
{
  sshPublicKeys = {
    apricity = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG0Zuk/bYRvsX5WypXgY7aopBeoTNjma1rr6Txtp87JS ssh-apricity";
    surge = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLSD33Pxjchgjm+JUtKKB7mtPhY05647eN69eBNOAg7 ssh-surge";
    age = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHdOxmUp8REg9IBoipLV40VYmLNiD6+TUUHb/ofyor60 ssh-age";
  };

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
      modules,
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit self inputs; };
      modules = modules ++ [
        { nixpkgs.pkgs = self.lib.mkPkgs system; }
      ];
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

  checkRekey = import ./check-rekey.nix { inherit self inputs; };
}
// import ./import.nix { inherit self inputs; }
// import ./tree.nix { inherit self inputs; }
