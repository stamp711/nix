{
  description = "My nix config";

  inputs = {
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

    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }@inputs:
    let
      inherit (nixpkgs.lib) attrValues optionalAttrs;

      nixpkgsConfig = {
        config.allowUnfree = true;
        # Somehow I have to add this to get vscode to install
        config.allowUnfreePredicate = (pkg: true);
        overlays = attrValues self.overlays;
        # Can be used to substitute in x86_64 packages on Apple Silicon
        # ++ nixpkgs.lib.singleton (self: super: { inherit (self.pkgs-x86_64) vim; });
      };
    in {

      overlays = {
        apple-silicon-x86_64-packages = self: super:
          optionalAttrs (super.stdenv.system == "aarch64-darwin") {
            # Add access to x86_64 packages on Apple Silicon
            pkgs-x86_64 = import nixpkgs {
              system = "x86_64-darwin";
              inherit (nixpkgsConfig) config;
            };
          };
        vscode-extensions = inputs.nix-vscode-extensions.overlays.default;
      };

      darwinConfigurations = {
        "Lius-MacBook" = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs; };
          modules = [
            ./darwin.nix
            home-manager.darwinModules.home-manager
            {
              nixpkgs = nixpkgsConfig;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users."stamp" = { imports = [ ./home.nix ]; };
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
        };
      };

      homeConfigurations."stamp@darwin" =

        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."aarch64-darwin";
          extraSpecialArgs = { inherit (inputs) nix-colors; };
          modules = [
            {
              nixpkgs = nixpkgsConfig;
              home.username = "stamp";
              home.homeDirectory = "/Users/stamp";
            }
            ./home.nix
          ];
        };

      homeConfigurations."stamp@x86_64-darwin" =

        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-darwin";
          extraSpecialArgs = { inherit (inputs) nix-colors; };
          modules = [
            {
              nixpkgs = nixpkgsConfig;
              home.username = "stamp";
              home.homeDirectory = "/Users/stamp";
            }
            ./home.nix
          ];
        };

      homeConfigurations."stamp@linux" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
          extraSpecialArgs = { inherit (inputs) nix-colors; };
          modules = [
            {
              nixpkgs = nixpkgsConfig;
              home.username = "stamp";
              home.homeDirectory = "/home/stamp";
            }
            ./home.nix
          ];
        };

    };
}
