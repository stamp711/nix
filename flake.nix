{
  description = "Reusable Nix configuration modules";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-colors = {
      url = "github:misterio77/nix-colors";
      inputs.nixpkgs-lib.follows = "flake-parts/nixpkgs-lib";
    };
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opnix = {
      url = "github:brizzbuzz/opnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    age-plugin-op = {
      url = "github:bromanko/age-plugin-op";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jj-starship = {
      url = "github:dmmulroy/jj-starship";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ssh-keys = {
      url = "https://github.com/stamp711.keys";
      flake = false;
    };
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    # flake-parts for perSystem only; flake-level outputs merged via //
    # to avoid flake-parts wrapping standard outputs (e.g. nixosModules)
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      perSystem =
        { pkgs, system, ... }:
        let
          treefmt = inputs.treefmt-nix.lib.evalModule pkgs {
            projectRootFile = null;
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
          };
        in
        {
          _module.args.pkgs = self.lib.mkPkgs system;

          formatter = treefmt.config.build.wrapper;

          checks = {
            formatting = treefmt.config.build.check self;
            statix = pkgs.runCommand "statix" { } ''
              ${pkgs.statix}/bin/statix check ${self} -c ${self}/statix.toml
              touch $out
            '';
            deadnix = pkgs.runCommand "deadnix" { } ''
              ${pkgs.deadnix}/bin/deadnix --fail ${self}
              touch $out
            '';
          };

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.statix
              pkgs.deadnix
              pkgs.nix-output-monitor
              pkgs.fx
              inputs.deploy-rs.packages.${system}.default
              inputs.agenix-rekey.packages.${system}.default
              inputs.age-plugin-op.defaultPackage.${system}
            ];
            inputsFrom = [ treefmt.config.build.devShell ];
          };

          apps = import ./apps.nix { inherit pkgs inputs; };
        };
    }
    // (
      let
        inherit (inputs.nixpkgs) lib;

        # Load host definitions
        hosts = self.lib.importDir ./hosts { args = { inherit self inputs; }; };

        # Generate NixOS configurations from hosts
        hostsWithNixos = lib.filterAttrs (_: host: host.nixosConfiguration or null != null) hosts;
        nixosConfigEntries = lib.mapAttrs' (
          _: host:
          lib.nameValuePair host.hostname {
            description = host.description or null;
            module = host.nixosConfiguration;
          }
        ) hostsWithNixos;

        # Generate home config entries from hosts
        hostsWithHome = lib.filterAttrs (_: host: host.homeConfiguration or null != null) hosts;
        homeConfigEntries = lib.mapAttrs' (
          _: host:
          lib.nameValuePair "${host.username}@${host.hostname}" {
            description = host.description or null;
            module = host.homeConfiguration;
          }
        ) hostsWithHome;

        # Generate deploy-rs node entries from hosts
        hostsWithDeploy = lib.filterAttrs (_: host: host.deploy or null != null) hosts;
        deployNodeEntries = lib.mapAttrs (_: host: {
          description = host.description or null;
          module = host.deploy // {
            profiles =
              lib.optionalAttrs (host.homeConfiguration or null != null) {
                home-manager = {
                  user = host.username;
                  path = inputs.deploy-rs.lib.${host.system}.activate.home-manager host.homeConfiguration;
                };
              }
              // lib.optionalAttrs (host.nixosConfiguration or null != null) {
                system = {
                  user = "root";
                  path = inputs.deploy-rs.lib.${host.system}.activate.nixos host.nixosConfiguration;
                };
              };
          };
        }) hostsWithDeploy;
      in
      {
        # ----- Library functions -----
        lib = import ./lib { inherit self inputs; };

        # ----- Home Manager -----
        homeModuleEntries = self.lib.importDir ./modules/home { collect = true; };
        homeModules = self.lib.importDir ./modules/home {
          mapper = m: m.module or m;
          collect = true;
        };

        homeProfileEntries = self.lib.importDir ./profiles/home { };
        homeProfiles = lib.mapAttrs (_: e: e.module or e) self.homeProfileEntries;

        inherit homeConfigEntries;
        homeConfigurations = lib.mapAttrs (_: e: e.module) homeConfigEntries;

        # ----- NixOS -----
        nixosModuleEntries = self.lib.importDir ./modules/nixos { collect = true; };
        nixosModules = self.lib.importDir ./modules/nixos {
          mapper = m: m.module or m;
          collect = true;
        };

        nixosProfileEntries = self.lib.importDir ./profiles/nixos { };
        nixosProfiles = lib.mapAttrs (_: e: e.module or e) self.nixosProfileEntries;

        inherit nixosConfigEntries;
        nixosConfigurations = lib.mapAttrs (_: e: e.module) nixosConfigEntries;

        # ----- Overlays -----
        overlays = import ./overlays.nix { inherit inputs; };

        # ----- age-rekey -----
        agenix-rekey = inputs.agenix-rekey.configure {
          userFlake = self;
          # inherit (self) nixosConfigurations;
          nixosConfigurations = {
            inherit (self.nixosConfigurations) NURO;
          };
        };

        # ----- Deploy-rs -----
        inherit deployNodeEntries;
        deploy.nodes = lib.mapAttrs (_: e: e.module) deployNodeEntries;
      }
    );
}
