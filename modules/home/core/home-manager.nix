{
  description = "Home Manager base configuration";

  module =
    { config, pkgs, ... }:
    {
      home.stateVersion = "26.05";

      home.homeDirectory =
        if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";

      xdg.enable = true;

      programs.home-manager.enable = true;
    };
}
