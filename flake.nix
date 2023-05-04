{
  description = "My nix config";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

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

    nix-index-database.url = "github:Mic92/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nix-colors.url = "github:misterio77/nix-colors";

    comma.url = "github:nix-community/comma";
    comma.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }@inputs:
    let
      inherit (self) outputs lib;

      nixpkgsConfig = {
        allowUnfree = true;
        # Workaround for https://github.com/nix-community/home-manager/issues/2942
        allowUnfreePredicate = (_: true);
      };

      nixpkgsOverlays = lib.attrValues outputs.overlays ++ [
        inputs.comma.overlays.default
        inputs.nix-vscode-extensions.overlays.default
      ];
      # # Can be used to substitute in x86_64 packages on Apple Silicon
      # ++ nixpkgs.lib.singleton (self: super: { inherit (self.pkgs-x86_64) vim; });

    in {

      lib = nixpkgs.lib // {

        mkDarwinConfigWithHomeManager = { system, user ? "stamp"
          , specialArgs ? { inherit self inputs outputs; }
          , baseDarwinModules ? [ self.darwinModules.base ]
          , extraDarwinModules ? [ ] }:
          darwin.lib.darwinSystem {
            inherit system specialArgs;
            modules = baseDarwinModules ++ extraDarwinModules ++ [
              {
                nixpkgs.config = nixpkgsConfig;
                nixpkgs.overlays = nixpkgsOverlays;
              }
              (self.darwinModules.setUserHome user)
              inputs.home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = specialArgs;
                home-manager.users.${user}.imports = [ ./home.nix ];
              }
            ];
          };

        mkDarwinConfig = { system }:
          darwin.lib.darwinSystem {
            system = system;
            specialArgs = { inherit inputs outputs; };
            modules = [
              ./darwin.nix
              {
                nixpkgs.config = nixpkgsConfig;
                nixpkgs.overlays = nixpkgsOverlays;
              }
              home-manager.darwinModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = { inherit inputs outputs; };
                home-manager.users."stamp".imports = [ ./home.nix ];
              }
            ];
          };
      };

      overlays = import ./overlays { inherit inputs outputs lib; };

      darwinModules = import ./modules/darwin { inherit lib; };

      darwinConfigurations = {
        stamp = lib.mkDarwinConfig { system = "x86_64-darwin"; };
        Lius-MacBook = lib.mkDarwinConfig { system = "aarch64-darwin"; };
        exp = lib.mkDarwinConfigWithHomeManager { system = "aarch64-darwin"; };
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
