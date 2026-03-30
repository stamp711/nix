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
      modules = [
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
        inputs.agenix-rekey.nixosModules.default
        { nixpkgs.pkgs = self.lib.mkPkgs system; }
      ]
      ++ modules;
    };

  # Create a system-manager configuration (for non-NixOS Linux).
  mkSystem =
    {
      system,
      modules ? [ ],
    }:
    inputs.system-manager.lib.makeSystemConfig {
      overlays = [
        inputs.agenix-rekey.overlays.default
        inputs.llm-agents.overlays.default
      ];
      modules = [
        {
          nixpkgs.hostPlatform = system;
          nixpkgs.config.allowUnfree = true;
        }
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
      modules = [
        inputs.nix-homebrew.darwinModules.nix-homebrew
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
  #
  # Works for paths from any flake by stripping the /nix/store/<hash>-<name>/ prefix.
  # In flake evaluation, all paths resolve to store paths with this structure:
  #   /nix/store/abc123-source/hosts/ssh-config.age
  #   ^^^^^^^^^^^^^^^^^^^^^^^^ 4 components when split by "/": "", "nix", "store", "<hash>-<name>"
  ageSecretName =
    path:
    let
      parts = lib.splitString "/" (toString path);
      relative = lib.concatStringsSep "/" (lib.drop 4 parts);
    in
    lib.removeSuffix ".age" (builtins.replaceStrings [ "/" ] [ "__" ] relative);

}
// import ./import.nix { inherit self inputs; }
