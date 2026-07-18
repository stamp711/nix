{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  flake.lib = {

    # Create a nixpkgs instance with our standard configuration.
    mkPkgs =
      {
        system,
        config ? { },
      }:
      import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        }
        // config;
        overlays = builtins.attrValues self.overlays ++ [
          inputs.agenix-rekey.overlays.default
          inputs.brew-nix.overlays.default
          inputs.nix-alien.overlays.default
        ];
      };

    # Create a NixOS system configuration.
    mkNixos =
      {
        system,
        nixpkgsConfig ? { },
        modules ? [ ],
      }:
      lib.nixosSystem {
        inherit system;
        modules = [
          inputs.disko.nixosModules.disko
          inputs.agenix.nixosModules.default
          inputs.agenix-rekey.nixosModules.default
          {
            nixpkgs.pkgs = self.lib.mkPkgs {
              inherit system;
              config = nixpkgsConfig;
            };
          }
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
          { nixpkgs.pkgs = self.lib.mkPkgs { inherit system; }; }
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
        pkgs = self.lib.mkPkgs { inherit system; };
        modules = [
          inputs.agenix.homeManagerModules.default
          # TODO: use inputs.agenix-rekey.homeManagerModules.default once
          # https://github.com/oddlama/agenix-rekey/pull/143 is merged
          (import "${inputs.agenix-rekey}/modules/agenix-rekey.nix" inputs.nixpkgs)
        ]
        ++ modules;
      };

  };
}
