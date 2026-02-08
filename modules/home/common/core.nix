# Core home-manager and nix configuration
{
  description = "Core home-manager and nix configuration";

  module =
    { config, pkgs, ... }:
    {
      home.stateVersion = "26.05";

      home.homeDirectory =
        if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";

      # XDG base directories
      xdg.enable = true;

      # Home Manager self-management
      programs.home-manager.enable = true;

      # Nix configuration
      nix.package = pkgs.nix;
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      # nh (nix helper) configuration
      home.sessionVariables.NH_FLAKE = "github:stamp711/nix";
    };
}
