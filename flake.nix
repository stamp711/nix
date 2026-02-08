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
    deploy-rs = {
      url = "github:serokell/deploy-rs";
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
        let
          treefmt = inputs.treefmt-nix.lib.evalModule pkgs {
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
              inputs.deploy-rs.packages.${system}.default
            ];
            inputsFrom = [ treefmt.config.build.devShell ];
          };
        };

      flake =
        let
          inherit (inputs.nixpkgs) lib;

          # Load host definitions
          hosts = self.lib.loadDir ./hosts { inherit self inputs; };

          # Generate named host-specific configs from host files
          hostsWithHome = lib.filterAttrs (_: host: host.homeConfiguration or null != null) hosts;
          hostHomeConfigs = lib.mapAttrs' (
            _: host: lib.nameValuePair "${host.username}@${host.hostname}" host.homeConfiguration
          ) hostsWithHome;

          # Manual template configs for common cases
          templateHomeConfigs = {
            # Generic work devbox configuration (Linux)
            work-devbox = self.lib.mkHome {
              system = "x86_64-linux";
              inherit (inputs.private.work.hosts.dev) username;
              modules = [ self.homeProfiles.work-devbox ];
            };
          };

          # Generate deploy-rs nodes from hosts with deploy config
          hostsWithDeploy = lib.filterAttrs (_: host: host.deploy or null != null) hosts;
          deployNodes = lib.mapAttrs (
            _: host:
            let
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
            in
            host.deploy // { inherit profiles; }
          ) hostsWithDeploy;
        in
        {
          # Library functions
          lib = import ./lib.nix { inherit self inputs; };

          # Home Manager
          homeModules = {
            common = self.lib.importDir ./modules/home;
            personal = self.lib.importDir ./modules/home-personal;
            work = self.lib.importDir ./modules/home-work;
          };

          homeProfiles = self.lib.importDir ./profiles/home;

          # Overlays
          overlays = import ./overlays.nix { inherit inputs; };

          # Home configurations
          # Combine both automatic and manual configs
          homeConfigurations = hostHomeConfigs // templateHomeConfigs;

          # Deploy-rs
          deploy.nodes = deployNodes;
        };
    };
}
