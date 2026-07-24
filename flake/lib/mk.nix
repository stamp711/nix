{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;

  # Operator identity for agenix-rekey. Used on the workstation at rekey time;
  # hosts decrypt with their own key via age.identityPaths.
  rekeyConfig = {
    age.rekey = {
      masterIdentities = [
        {
          identity = ./ssh-age.pub;
          pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHdOxmUp8REg9IBoipLV40VYmLNiD6+TUUHb/ofyor60 ssh-age";
        }
      ];
      storageMode = "local";
      localStorageDir = lib.mkDefault "${self}/.rekey";
    };
  };
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

    nixosBaseModules =
      {
        system,
        nixpkgsConfig ? { },
        rekey ? true,
      }:
      [
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
      ]
      ++ lib.optionals rekey [
        inputs.agenix-rekey.nixosModules.default
        rekeyConfig
      ]
      ++ [
        {
          nixpkgs.pkgs = self.lib.mkPkgs {
            inherit system;
            config = nixpkgsConfig;
          };
        }
      ];

    # Create a NixOS system configuration.
    mkNixos =
      {
        system,
        nixpkgsConfig ? { },
        modules ? [ ],
      }:
      lib.nixosSystem {
        inherit system;
        modules = self.lib.nixosBaseModules { inherit system nixpkgsConfig; } ++ modules;
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

    homeBaseModules =
      {
        rekey ? true,
      }:
      [ inputs.agenix.homeManagerModules.default ]
      ++ lib.optionals rekey [
        # TODO: use inputs.agenix-rekey.homeManagerModules.default once
        # https://github.com/oddlama/agenix-rekey/pull/143 is merged
        (import "${inputs.agenix-rekey}/modules/agenix-rekey.nix" inputs.nixpkgs)
        rekeyConfig
      ];

    # Create a home-manager configuration. Set my.primaryUser in modules.
    mkHome =
      {
        system,
        modules ? [ ],
      }:
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = self.lib.mkPkgs { inherit system; };
        modules = self.lib.homeBaseModules { } ++ modules;
      };

  };
}
