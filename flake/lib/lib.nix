{ self, inputs }:
let
  inherit (inputs.nixpkgs) lib;
in
rec {
  sshPublicKeys = {
    apricity = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG0Zuk/bYRvsX5WypXgY7aopBeoTNjma1rr6Txtp87JS ssh-apricity";
    age = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHdOxmUp8REg9IBoipLV40VYmLNiD6+TUUHb/ofyor60 ssh-age";
    work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICvYg3Qb8kAY7RD/3Y3uxaInkgxtUJ0o/Lb+7vkIcB1O";
  };

  # Create a nixpkgs instance with our standard configuration.
  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = builtins.attrValues self.overlays;
    };

  # Extract modules of a given class from a list of aspects.
  extractAspects = class: aspects: lib.filter (x: x != null) (map (a: a.${class} or null) aspects);

  # Aspects included in every configuration.
  defaultAspects = with self.aspectModules; [
    core
    my
  ];

  # Create a NixOS system configuration.
  mkNixos =
    {
      system,
      aspects ? [ ],
      modules ? [ ],
    }:
    lib.nixosSystem {
      inherit system;
      specialArgs = { inherit self inputs; };
      modules = [
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
        inputs.agenix-rekey.nixosModules.default
        { nixpkgs.pkgs = self.lib.mkPkgs system; }
      ]
      ++ modules
      ++ extractAspects "nixos" (defaultAspects ++ aspects);
    };

  # Create a nix-darwin system configuration.
  mkDarwin =
    {
      system,
      primaryUser,
      aspects ? [ ],
      modules ? [ ],
    }:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit self inputs; };
      modules = [
        inputs.determinate.darwinModules.default
        { nixpkgs.pkgs = self.lib.mkPkgs system; }
        { system.primaryUser = primaryUser; }
      ]
      ++ modules
      ++ extractAspects "darwin" (defaultAspects ++ aspects);
    };

  # Create a home-manager configuration from system, username, and modules.
  mkHome =
    {
      system,
      username,
      aspects ? [ ],
      modules ? [ ],
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = self.lib.mkPkgs system;
      extraSpecialArgs = { inherit self inputs; };
      modules = [
        inputs.agenix.homeManagerModules.default
        # TODO: use inputs.agenix-rekey.homeManagerModules.default once
        # https://github.com/oddlama/agenix-rekey/pull/143 is merged
        (import "${inputs.agenix-rekey}/modules/agenix-rekey.nix" inputs.nixpkgs)
        { home.username = username; }
        self.homeModules.core
      ]
      ++ modules
      ++ extractAspects "homeManager" (defaultAspects ++ aspects);
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
