{
  description = "You new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:nixos/nixos-hardware";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { nixpkgs, home-manager, nix-colors, ... }@inputs: rec {

    homeConfigurations."stamp@darwin" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-darwin";
      extraSpecialArgs = { inherit nix-colors; };
      modules = [
        {
          home.username = "stamp";
          home.homeDirectory = "/Users/stamp";
        }
        ./home.nix
      ];
    };

    homeConfigurations."stamp@linux" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      extraSpecialArgs = { inherit nix-colors; };
      modules = [
        {
          home.username = "stamp";
          home.homeDirectory = "/home/stamp";
        }
        ./home.nix
      ];
    };

    homeConfigurations."REDACTED@linux" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      extraSpecialArgs = { inherit nix-colors; };
      modules = [
        {
          home.username = "REDACTED";
          home.homeDirectory = "/home/REDACTED";
        }
        ./home.nix
      ];
    };

  };
}
