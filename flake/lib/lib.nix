{ self, inputs }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  # Create a nixpkgs instance with our standard configuration.
  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = builtins.attrValues self.overlays ++ [
        inputs.agenix-rekey.overlays.default
        inputs.llm-agents.overlays.default
        inputs.brew-nix.overlays.default
      ];
    };

  # Create a NixOS system configuration.
  mkNixos =
    {
      system,
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
      ++ modules;
    };

  # Create a nix-darwin system configuration.
  mkDarwin =
    {
      system,
      modules ? [ ],
    }:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit self inputs; };
      modules = [
        inputs.determinate.darwinModules.default
        { nixpkgs.pkgs = self.lib.mkPkgs system; }
      ]
      ++ modules;
    };

  # Create a home-manager configuration. Set my.primaryUser in modules.
  mkHome =
    {
      system,
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
      ]
      ++ modules;
    };

  # Derive a stable secret name from a .age file path, relative to the flake root.
  # e.g. profiles/nixos/kvm-proxy/xray-proxy.env.age => profiles__nixos__kvm-proxy__xray-proxy.env
  ageSecretName =
    path:
    let
      relative = lib.removePrefix (toString self + "/") (toString path);
    in
    lib.removeSuffix ".age" (builtins.replaceStrings [ "/" ] [ "__" ] relative);

}
// import ./import.nix { inherit self inputs; }
