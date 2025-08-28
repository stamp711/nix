{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-colors.url = "github:misterio77/nix-colors";
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # systems = inputs.nixpkgs.lib.systems.flakeExposed;
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      perSystem =
        { pkgs, system, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = builtins.attrValues self.overlays;
          };
          formatter = pkgs.nixfmt-tree;
          devShells.default = import ./shell.nix { inherit pkgs; };
          legacyPackages.homeConfigurations.stamp = inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            extraSpecialArgs = {
              inherit inputs;
            };
            modules = [ ./home ];
          };
        };

      flake = {
        deploy = {
          remoteBuild = true;
          nodes.wsl = {
            hostname = "wsl";
            profiles.stamp = {
              user = "stamp";
              path = inputs.deploy-rs.lib.x86_64-linux.activate.home-manager self.legacyPackages.x86_64-linux.homeConfigurations.stamp;
            };
          };
        };
        overlays = import ./overlays.nix { inherit inputs; };
        templates = {
          default = {
            path = ./templates/basic;
            description = "Basic Nix development environment";
          };
          rust = {
            path = ./templates/rust;
            description = "Rust development environment";
          };
          cpp = {
            path = ./templates/cpp;
            description = "C++ development environment";
          };
          python = {
            path = ./templates/python;
            description = "Python development environment with uv";
          };
        };
      };
    };
}
