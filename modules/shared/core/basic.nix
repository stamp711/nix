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
      programs.nh.flake = "github:stamp711/nix";
    };

  flake.darwinModules.core = {
    system.stateVersion = 6;
    system.defaults.NSGlobalDomain = {
      KeyRepeat = 1;
      InitialKeyRepeat = 15;
    };
  };

  flake.nixosModules.core = {
    system.stateVersion = "26.05";
    time.timeZone = "Asia/Shanghai";
    i18n.defaultLocale = "en_US.UTF-8";
    security.sudo.wheelNeedsPassword = false;
    environment.enableAllTerminfo = true; # Terminfo for ghostty, kitty, foot, etc.
    programs.nix-ld.enable = true; # Run unpatched dynamic binaries on NixOS

    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings.main.capslock = "leftcontrol";
      };
    };

    programs.nh.enable = true;
    programs.nh.flake = "github:stamp711/nix";
  };

}
