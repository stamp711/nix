{
  description = "Reusable Nix configuration modules";

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
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    private.url = "git+ssh://git@github.com/stamp711/nix-private";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
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

          formatter =
            (inputs.treefmt-nix.lib.evalModule pkgs {
              projectRootFile = "flake.nix";
              programs.nixfmt.enable = true;
              programs.stylua.enable = true;
              programs.prettier.enable = true;
              programs.clang-format.enable = true;
              settings.formatter.gersemi = {
                command = "${pkgs.gersemi}/bin/gersemi";
                options = [ "-i" ];
                includes = [
                  "**/CMakeLists.txt"
                  "**/*.cmake"
                ];
              };
            }).config.build.wrapper;

          devShells.default = import ./shell.nix { inherit pkgs; };
        };

      flake =
        let
          # Load host definitions
          hosts = self.lib.loadDir ./hosts { inherit self inputs; };

          # Generate named host-specific configs from host files
          hostConfigs = inputs.nixpkgs.lib.mapAttrs' (
            _: host: inputs.nixpkgs.lib.nameValuePair "${host.username}@${host.hostname}" host.homeConfiguration
          ) hosts;

          # Manual template configs for common cases
          templateConfigs = {
            # Generic work devbox configuration (Linux)
            work-devbox = inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = import inputs.nixpkgs {
                system = "x86_64-linux";
                config.allowUnfree = true;
              };
              extraSpecialArgs = { inherit self inputs; };
              modules = [ self.homeProfiles.work-devbox ];
            };
          };

          # Combine both automatic and manual configs
          homeConfigurations = hostConfigs // templateConfigs;
        in
        {
          # Library functions
          lib = import ./lib { lib = inputs.nixpkgs.lib; };

          # Home Manager
          homeModules = self.lib.importDir ./modules/home;
          homePersonalModules = self.lib.importDir ./modules/home-personal;
          homeWorkModules = self.lib.importDir ./modules/home-work;
          homeProfiles = self.lib.importDir ./profiles/home;

          # Overlays
          overlays = import ./overlays.nix { inherit inputs; };

          # Home configurations
          inherit homeConfigurations;

          # Templates
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
