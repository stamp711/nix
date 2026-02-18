{ self, inputs }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  sshPublicKeys = {
    apricity = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG0Zuk/bYRvsX5WypXgY7aopBeoTNjma1rr6Txtp87JS ssh-apricity";
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
    lib.nixosSystem {
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

  # Derive a stable secret name from a .age file path, relative to the flake root.
  # e.g. profiles/nixos/kvm-proxy/xray-proxy.env.age => profiles__nixos__kvm-proxy__xray-proxy.env
  ageSecretName =
    path:
    let
      relative = lib.removePrefix (toString self + "/") (toString path);
    in
    lib.removeSuffix ".age" (builtins.replaceStrings [ "/" ] [ "__" ] relative);

  checkRekey = import ./check-rekey.nix { inherit self inputs; };
}
// import ./import.nix { inherit self inputs; }
// import ./tree.nix { inherit self inputs; }
