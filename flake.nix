{
  description = "My nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:nixos/nixos-hardware";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # VSCode extensions
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { nixpkgs, home-manager, nix-vscode-extensions, nix-colors, ...
    }@inputs: rec {
      homeConfigurations."stamp@darwin" =

        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."aarch64-darwin";
          extraSpecialArgs = { inherit nix-vscode-extensions nix-colors; };
          modules = [
            {
              home.username = "stamp";
              home.homeDirectory = "/Users/stamp";
            }
            ./home.nix
          ];
        };

      homeConfigurations."stamp@darwin-intel" =

        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-darwin";
          extraSpecialArgs = { inherit nix-vscode-extensions nix-colors; };
          modules = [
            {
              home.username = "stamp";
              home.homeDirectory = "/Users/stamp";
            }
            ./home.nix
          ];
        };

      homeConfigurations."stamp@linux" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
          extraSpecialArgs = { inherit nix-vscode-extensions nix-colors; };
          modules = [
            {
              home.username = "stamp";
              home.homeDirectory = "/home/stamp";
            }
            ./home.nix
          ];
        };

    };
}
