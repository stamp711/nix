{
  inputs,
  lib,
  self,
  ...
}:
let
  # agenix and agenix-rekey, with shared runtime plugins and operator policy.
  agenixConfig =
    {
      _class,
      options,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.agenix-rekey."${_class}Modules".default ]; # agenix module is unconditionally imported in each mk helper, because my/ modules use its options

      age = self.lib.mergeDisjoint [
        # select age binary for hosts. HM and system modules option name differ.
        (
          let
            package = (pkgs.age.withPlugins builtins.attrValues).overrideAttrs (
              old:
              assert !(old ? meta.mainProgram);
              {
                meta.mainProgram = "age";
              }
            );
          in
          if _class == "homeManager" then
            { package = lib.mkDefault package; }
          else
            { ageBin = lib.mkDefault "${package}/bin/age"; }
        )
        {
          rekey = {
            # Used on the workstation; hosts decrypt with age.identityPaths.
            masterIdentities = [
              {
                identity = ./ssh-age.pub;
                pubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHdOxmUp8REg9IBoipLV40VYmLNiD6+TUUHb/ofyor60 ssh-age";
              }
            ];
            storageMode = "local"; # Local mode needs store writes during evaluation; `nix run .#check` prepares them.
            hostPubkey = lib.mkDefault options.age.rekey.hostPubkey.default; # default to agenix-rekey's dummy key
          };
        }
      ];
    };
in
{
  flake.lib = {

    # Ours plus the inputs', for every package set however it gets instantiated.
    allOverlays = [
      inputs.agenix-rekey.overlays.default
      inputs.brew-nix.overlays.default
      inputs.nix-alien.overlays.default
      inputs.nur.overlays.default
    ]
    ++ builtins.attrValues self.overlays;

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
        rekey,
        nixpkgsConfig ? { },
      }:
      [
        inputs.disko.nixosModules.disko
        inputs.agenix.nixosModules.default
        {
          nixpkgs.pkgs = self.lib.mkPkgs {
            inherit system;
            config = nixpkgsConfig;
          };
        }
      ]
      ++ lib.optional rekey agenixConfig;

    darwinBaseModules =
      {
        system,
        nixpkgsConfig ? { },
      }:
      [
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.nix-apple-container.darwinModules.default
        inputs.agenix.darwinModules.default
        agenixConfig
        {
          nixpkgs.pkgs = self.lib.mkPkgs {
            inherit system;
            config = nixpkgsConfig;
          };
        }
      ];

    homeBaseModules = [
      inputs.agenix.homeManagerModules.default
      agenixConfig
      {
        # https://github.com/nix-community/home-manager/pull/10000
        disabledModules = [ "programs/codex" ];
        imports = [ "${inputs.hm-codex-pr}/modules/programs/codex" ];
      }
    ];

    # Create a NixOS system configuration.
    mkNixos =
      {
        system,
        rekey ? true,
        nixpkgsConfig ? { },
        modules ? [ ],
      }:
      inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = self.lib.nixosBaseModules { inherit system nixpkgsConfig rekey; } ++ modules;
      };

    # Create a nix-darwin system configuration.
    mkDarwin =
      {
        system,
        nixpkgsConfig ? { },
        modules ? [ ],
      }:
      inputs.nix-darwin.lib.darwinSystem {
        inherit system;
        modules = self.lib.darwinBaseModules { inherit system nixpkgsConfig; } ++ modules;
      };

    # Create a home-manager configuration. Set my.primaryUser in modules.
    mkHome =
      {
        system,
        nixpkgsConfig ? { },
        modules ? [ ],
      }:
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = self.lib.mkPkgs {
          inherit system;
          config = nixpkgsConfig;
        };
        modules = self.lib.homeBaseModules ++ modules;
      };

    # Home-manager embedded in a NixOS or nix-darwin system, as a module for it.
    mkHomeModule =
      {
        username,
        modules ? [ ],
      }:
      { _class, ... }:
      {
        imports = [ inputs.home-manager."${_class}Modules".home-manager ];

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${username}.imports = self.lib.homeBaseModules ++ modules;
        };
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

  };
}
