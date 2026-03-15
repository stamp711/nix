{
  flake.profiles.homeManager.headless =
    { self, ... }:
    {
      imports = [
        self.profiles.homeManager.minimal
        self.homeModules.tools
      ];

      my.maintenance.autoUpdate = true;
      my.maintenance.autoClean = true;
    };

  flake.profiles.nixos.headless =
    { self, pkgs, ... }:
    {
      imports = [
        self.profiles.nixos.minimal
      ];

      my.maintenance.autoUpdate = true;
      my.maintenance.autoClean = true;

      programs.zsh.enable = true;
      users.defaultUserShell = pkgs.zsh;
    };
}
