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
    utils.url = "path:./nix-utils";
    private = {
      url = "git+ssh://git@github.com/stamp711/nix-private";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "utils";
    };
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
              pkgs.fx
              inputs.deploy-rs.packages.${system}.default
            ];
            inputsFrom = [ treefmt.config.build.devShell ];
          };

          # Show module tree structure
          # Use: nix run .#show-modules [--json|--tree]
          # ANSI: \u001b[1m = bold, \u001b[2m = dim, \u001b[0m = reset
          apps.show-modules = {
            type = "app";
            meta.description = "Show module tree with descriptions";
            program = toString (
              pkgs.writeShellScript "show-modules" ''
                json=$(${pkgs.nix}/bin/nix eval .#lib.moduleTree --json 2>/dev/null)
                case "$1" in
                  --json) echo "$json" | ${pkgs.jq}/bin/jq . ;;
                  --tree|"")
                    echo "$json" | ${pkgs.jq}/bin/jq -r '
                      def tree(prefix):
                        (keys | last) as $last |
                        to_entries[] |
                        (.key == $last) as $is_last |
                        (if $is_last then "└── " else "├── " end) as $branch |
                        (if $is_last then "    " else "│   " end) as $ext |
                        (if .value | type == "string" then ": \u001b[2m\(.value)\u001b[0m" else "" end) as $desc |
                        "\(prefix)\($branch)\u001b[1m\(.key)\u001b[0m\($desc)",
                        (if (.value | type) == "object" then .value | tree("\(prefix)\($ext)") else empty end);
                      tree("")
                    ' ;;
                  *) echo "Usage: show-modules [--json|--tree]" ;;
                esac
              ''
            );
          };
        };

      flake =
        let
          inherit (inputs.nixpkgs) lib;

          # Load host definitions
          hosts = self.lib.importDir ./hosts { args = { inherit self inputs; }; };

          # Generate named host-specific configs from host files
          # Format: { description, module }
          hostsWithHome = lib.filterAttrs (_: host: host.homeConfiguration or null != null) hosts;
          hostHomeEntries = lib.mapAttrs' (
            _: host:
            lib.nameValuePair "${host.username}@${host.hostname}" {
              description = host.description or null;
              module = host.homeConfiguration;
            }
          ) hostsWithHome;

          # Manual template configs for common cases
          templateHomeEntries = {
            work-devbox = {
              description = "Generic work devbox";
              module = self.lib.mkHome {
                system = "x86_64-linux";
                inherit (inputs.private.work.hosts.dev) username;
                modules = [ self.homeProfiles.work-devbox ];
              };
            };
          };

          # Combined entries
          homeConfigEntries = hostHomeEntries // templateHomeEntries;

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
          lib = import ./lib { inherit self inputs; };

          # Home Manager
          # Extract .module from wrappers, or use as-is if already a function
          homeModules = self.lib.importDir ./modules/home {
            mapper = m: m.module or m;
            collect = true;
          };

          homeProfiles = self.lib.importDir ./profiles/home { };

          # Overlays
          overlays = import ./overlays.nix { inherit inputs; };

          # Home configurations (extract .module from entries)
          homeConfigurations = lib.mapAttrs (_: e: e.module) homeConfigEntries;

          # Raw entries with descriptions for tree visualization
          inherit homeConfigEntries;

          # Deploy-rs
          deploy.nodes = deployNodes;
        };
    };
}
