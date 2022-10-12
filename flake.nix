{
  description = "You new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:nixos/nixos-hardware";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { nixpkgs, home-manager, ... }@inputs: rec {
    
    homeConfigurations."stamp@darwin" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-darwin";
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
