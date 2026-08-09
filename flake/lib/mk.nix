{
  inputs,
  lib,
  self,
  ...
}:
let
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
    };
  };
in
{
  flake.lib = {

    # Ours plus the inputs', for every package set however it gets instantiated.
    allOverlays = builtins.attrValues self.overlays ++ [
      inputs.agenix-rekey.overlays.default
      inputs.brew-nix.overlays.default
      inputs.nix-alien.overlays.default
    ];

    # Create a nixpkgs instance with our standard configuration.
    mkPkgs =
      {
        system,
        config ? { },
      }:
      import inputs.nixpkgs {
        inherit system;
        config = lib.attrsets.unionOfDisjoint config { allowUnfree = true; };
        overlays = self.lib.allOverlays;
      };

    nixosBaseModules =
      {
        system,
        nixpkgsConfig ? { },
      }:
      [
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
        inputs.agenix-rekey.nixosModules.default
        rekeyConfig
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
      inputs.nixpkgs.lib.nixosSystem {
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
        # It instantiates nixpkgs itself; nixpkgs.pkgs is read-only, so mkPkgs cannot be used.
        overlays = self.lib.allOverlays;
        modules = [
          {
            nixpkgs.hostPlatform = system;
            nixpkgs.config.allowUnfree = true;
          }
        ]
        ++ modules;
      };

    darwinBaseModules =
      { system, rekey }:
      [
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.nix-apple-container.darwinModules.default
        inputs.agenix.darwinModules.default
        { nixpkgs.pkgs = self.lib.mkPkgs { inherit system; }; }
      ]
      ++ lib.optionals rekey [
        inputs.agenix-rekey.darwinModules.default
        rekeyConfig
      ];

    # Create a nix-darwin system configuration.
    mkDarwin =
      {
        system,
        # with no hostPubkey agenix-rekey warns with networking.hostName (default null) and errors
        rekey ? false,
        modules ? [ ],
      }:
      inputs.nix-darwin.lib.darwinSystem {
        inherit system;
        modules = self.lib.darwinBaseModules { inherit system rekey; } ++ modules;
      };

    homeBaseModules = [
      inputs.agenix.homeManagerModules.default
      inputs.agenix-rekey.homeManagerModules.default
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
        modules = self.lib.homeBaseModules ++ modules;
      };

  };
}
