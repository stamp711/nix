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

      mkPkgs = system:
        import inputs.nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            # Workaround for https://github.com/nix-community/home-manager/issues/2942
            allowUnfreePredicate = (_: true);
          };
          overlays = lib.attrValues outputs.overlays ++ [
            inputs.comma.overlays.default
            inputs.nix-vscode-extensions.overlays.default
          ];
          # # Can be used to substitute in x86_64 packages on Apple Silicon
          # ++ nixpkgs.lib.singleton (self: super: { inherit (self.pkgs-x86_64) vim; });
        };

      mkHome = { username, system, pkgs ? mkPkgs system, lib ? self.lib
        , extraSpecialArgs ? { inherit self inputs nixpkgs; }, modules }:
        inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs lib extraSpecialArgs;
          modules = [{
            home = {
              inherit username;
              homeDirectory = "${lib.homePrefix system}/${username}";
            };
          }] ++ modules;
          # modules = baseModules ++ extraModules;
        };

      mkDarwin = { system, pkgs ? mkPkgs system, lib ? self.lib
        , specialArgs ? { inherit self inputs outputs; }, modules
        , baseModules ? [ outputs.darwinModules.base ], extraModules ? [ ] }:
        inputs.darwin.lib.darwinSystem {
          inherit system pkgs lib specialArgs modules;
        };

    in rec {

      lib = nixpkgs.lib // rec {
        isDarwin = system:
          (builtins.elem system inputs.nixpkgs.lib.platforms.darwin);
        homePrefix = system: if isDarwin system then "/Users" else "/home";
      };

      overlays = import ./overlays { inherit inputs outputs lib; };

      darwinModules = import ./modules/darwin { inherit lib; };

      darwinConfigurations = {
        stamp = lib.mkDarwinConfig { system = "x86_64-darwin"; };
        Lius-MacBook = lib.mkDarwinConfig { system = "aarch64-darwin"; };
        test = mkDarwin {
          system = "aarch64-darwin";
          modules = [ ./darwin.nix ];
        };
      };

      homeConfigurations = {

        "stamp@aarch64-darwin" = lib.mkHome {
          system = "aarch64-darwin";
          username = "stamp";
          modules = [ ./home.nix ];
        };

        "stamp@x86_64-linux" = lib.mkHome {
          system = "x86_64-linux";
          username = "stamp";
          modules = [ ./home.nix ];
        };

        # "stamp@x86_64-linux" = home-manager.lib.homeManagerConfiguration {
        #   pkgs = nixpkgs.legacyPackages."x86_64-linux";
        #   extraSpecialArgs = { inherit (inputs) nix-colors; };
        #   modules = [
        #     {
        #       nixpkgs = nixpkgsConfig;
        #       home.username = "stamp";
        #       home.homeDirectory = "/home/stamp";
        #     }
        #     ./home.nix
        #   ];
        # };

      };
    };
}
