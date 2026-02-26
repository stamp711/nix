{
  description = "Nix and nixpkgs configuration";

  module =
    { self, pkgs, ... }:
    {
      nix.package = pkgs.nix;
      nix.settings = self.lib.nixConfig;

      xdg.configFile."nixpkgs/config.nix".text = ''
        { allowUnfree = true; allowUnfreePredicate = _: true; }
      '';

      # nh (nix helper)
      programs.nh.enable = true;
      programs.nh.flake = "github:stamp711/nix";
    };
}
