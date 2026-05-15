{
  flake.nixosModules.linux-gaming = {
    programs.gamescope = {
      enable = true;
      capSysNice = true;
    };
  };
}
