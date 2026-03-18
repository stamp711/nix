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

}
