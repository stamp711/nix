{ inputs, ... }:
let
  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
in
{

  flake.homeModules.core =
    { pkgs, ... }:
    {
      nix.package = pkgs.nix;
      nix.registry.nixpkgs.flake = inputs.nixpkgs;
      nix.settings = nixConfig;
      xdg.configFile."nixpkgs/config.nix".text = ''
        { allowUnfree = true; allowUnfreePredicate = _: true; }
      '';
    };

  flake.darwinModules.core = {
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    nix.settings = nixConfig // {
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "@admin"
      ];
    };
  };

  flake.nixosModules.core = {
    nix.channel.enable = false;
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    nix.settings = nixConfig // {
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
  };

  flake.systemModules.core = {
    nix.enable = true;
    nix.settings = nixConfig // {
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "@wheel"
      ];
      # Clear nix-path to disable channels; use flake registry instead
      nix-path = "";
    };
    # system-manager lacks nix.registry; generate the registry file directly
    environment.etc."nix/registry.json".text = builtins.toJSON {
      version = 2;
      flakes = [
        {
          from = {
            type = "indirect";
            id = "nixpkgs";
          };
          to = {
            type = "path";
            path = inputs.nixpkgs.outPath;
            inherit (inputs.nixpkgs) lastModified rev narHash;
          };
        }
      ];
    };
  };

}
