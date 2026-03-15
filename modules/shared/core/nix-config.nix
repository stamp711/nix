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
    determinateNix = {
      enable = true;
      customSettings = nixConfig // {
        auto-optimise-store = true;
        trusted-users = [
          "root"
          "@admin"
        ];
        eval-cores = 0; # Enables parallel evaluation
        extra-experimental-features = [ ];
      };
    };
  };

  flake.nixosModules.core = {
    nix.channel.enable = false;
    nix.settings = nixConfig // {
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
  };

}
