{
  description = "My nix config";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:nixos/nixos-hardware";

    # nix-darwin
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # VSCode extensions
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:pta2002/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    # comma
    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      inherit (self) outputs lib;

      mkPkgs =
        system:
        import inputs.nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            # Workaround for https://github.com/nix-community/home-manager/issues/2942
            allowUnfreePredicate = _: true;
          };
          overlays = lib.attrValues outputs.overlays ++ [ inputs.nix-vscode-extensions.overlays.default ];
          # # Can be used to substitute in x86_64 packages on Apple Silicon
          # ++ nixpkgs.lib.singleton (self: super: { inherit (self.pkgs-x86_64) vim; });
        };

      mkUserInfo =
        { username, system }:
        rec {
          inherit username;
          homeDirectory = "${lib.homePrefix system}/${username}";
          nixConfigDirectory = "${homeDirectory}/.config/nixpkgs";
        };

      moduleExtraArgs = {
        inherit self inputs outputs;
      };

      mkHome =
        {
          username,
          system,
          modules,
        }:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          lib = self.lib;
          extraSpecialArgs = moduleExtraArgs;
          modules =
            lib.attrValues outputs.homeManagerModules
            ++ lib.singleton {
              home.user-info = mkUserInfo {
                inherit system;
                inherit username;
              };
            }
            ++ modules;
        };

      mkDarwin =
        {
          system,
          pkgs ? mkPkgs system,
          lib ? self.lib,
          specialArgs ? {
            inherit self inputs outputs;
          },
          modules,
        }:
        inputs.darwin.lib.darwinSystem {
          inherit system;
          pkgs = mkPkgs system;
          lib = self.lib;
          specialArgs = moduleExtraArgs;
          inherit modules;
        };

      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      forEachSystem = inputs.flake-utils.lib.eachSystem systems;
      genForEachSystem = f: nixpkgs.lib.attrsets.genAttrs systems f;
      genForEachPkgs = f: genForEachSystem (system: (f (mkPkgs system)));
    in
    {
      formatter = genForEachPkgs (pkgs: pkgs.nixfmt-rfc-style);

      lib = nixpkgs.lib // rec {
        isDarwin = system: (builtins.elem system inputs.nixpkgs.lib.platforms.darwin);
        homePrefix = system: if isDarwin system then "/Users" else "/home";
      };

      overlays = import ./overlays { inherit inputs outputs lib; };

      darwinModules = import ./modules/darwin;

      homeManagerModules = import ./modules/home;

      darwinConfigurations = {
        Lius-MacBook = mkDarwin {
          system = "aarch64-darwin";
          modules = [ ./darwin ];
        };

        stamp = mkDarwin {
          system = "x86_64-darwin";
          modules = [ ./darwin ];
        };
      };
    }
    // forEachSystem (system: {
      legacyPackages.homeConfigurations."stamp" = mkHome {
        inherit system;
        username = "stamp";
        modules = [ ./home ];
      };
    });
}
