{

  flake.homeModules.core =
    { config, pkgs, ... }:
    {
      home.stateVersion = "26.11";
      home.homeDirectory =
        if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";
      xdg.enable = true;
      programs.home-manager.enable = true;

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."*".StrictHostKeyChecking = "accept-new";
      };

      programs.nh.enable = true;
      programs.nh.flake = config.my.flake;
    };

  flake.darwinModules.core = {
    system.stateVersion = 6;
  };

  flake.nixosModules.core =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      system.stateVersion = "26.05";

      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

      time.timeZone = "Asia/Shanghai";
      i18n.defaultLocale = "en_US.UTF-8";
      users.mutableUsers = false;
      security.sudo.wheelNeedsPassword = false;
      environment.enableAllTerminfo = true; # Terminfo for ghostty, kitty, foot, etc.
      programs.nix-ld.enable = true; # Run unpatched dynamic binaries on NixOS

      programs.nh.enable = true;
      programs.nh.flake = config.my.flake;

      # System-core state that must survive @root wipes (impermanence).
      my.persistence.directories = [
        "/var/lib/nixos" # uid/gid maps for declarative users
        "/var/lib/systemd" # random-seed, timers, timesync, linger, credentials
        "/var/log" # system logs across boots
      ];
      my.persistence.files = [
        "/etc/machine-id" # systemd machine identity / journald
        "/etc/adjtime" # hwclock drift correction
      ];
    };

}
