{
  description = "You new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hardware.url = "github:nixos/nixos-hardware";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # ~bwolf's language-servers.nix
    language-servers.url = git+https://git.sr.ht/~bwolf/language-servers.nix;
    language-servers.inputs.nixpkgs.follows = "nixpkgs";

    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { nixpkgs, home-manager, nix-colors, language-servers, ... }@inputs: rec {

    homeConfigurations."stamp@darwin" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-darwin";
      extraSpecialArgs = { inherit nix-colors language-servers; };
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
      extraSpecialArgs = { inherit nix-colors language-servers; };
      modules = [
        {
          home.username = "stamp";
          home.homeDirectory = "/home/stamp";
        }
        ./home.nix
      ];
    };

    homeConfigurations."liuxuyang@linux" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      extraSpecialArgs = { inherit nix-colors language-servers; };
      modules = [
        {
          home.username = "liuxuyang";
          home.homeDirectory = "/home/liuxuyang";
        }
        ./home.nix
      ];
    };

  };
}
