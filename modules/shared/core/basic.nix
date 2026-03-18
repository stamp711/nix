{

  flake.homeModules.core =
    { config, pkgs, ... }:
    {
      home.stateVersion = "26.05";
      home.homeDirectory =
        if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";
      xdg.enable = true;
      programs.home-manager.enable = true;

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks."*".extraOptions.StrictHostKeyChecking = "accept-new";
      };

      programs.nh.enable = true;
      programs.nh.flake = config.my.flake;
    };

  flake.darwinModules.core = {
    system.stateVersion = 6;
  };

  flake.nixosModules.core =
    { config, ... }:
    {
      system.stateVersion = "26.05";
      time.timeZone = "Asia/Shanghai";
      i18n.defaultLocale = "en_US.UTF-8";
      security.sudo.wheelNeedsPassword = false;
      environment.enableAllTerminfo = true; # Terminfo for ghostty, kitty, foot, etc.
      programs.nix-ld.enable = true; # Run unpatched dynamic binaries on NixOS

      programs.nh.enable = true;
      programs.nh.flake = config.my.flake;
    };

}
