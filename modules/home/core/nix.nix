{
  description = "Nix and nixpkgs configuration";

  module =
    { pkgs, ... }:
    {
      nix.package = pkgs.nix;
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      xdg.configFile."nixpkgs/config.nix".text = ''
        { allowUnfree = true; allowUnfreePredicate = _: true; }
      '';
    };
}
