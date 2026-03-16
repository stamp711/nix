{
  flake.profiles.homeManager.headless =
    { self, ... }:
    {
      imports = [
        self.profiles.homeManager.minimal
        self.homeModules.shell
        self.homeModules.tools
      ];

      my.maintenance.autoUpdate = true;
      my.maintenance.autoClean = true;
    };

  flake.profiles.nixos.headless =
    { self, ... }:
    {
      imports = [
        self.profiles.nixos.minimal
        self.nixosModules.shell
        self.nixosModules.hardware
        self.nixosModules.tools
      ];

      my.maintenance.autoUpdate = true;
      my.maintenance.autoClean = true;
    };

  flake.profiles.darwin.headless =
    { self, ... }:
    {
      imports = [
        self.profiles.darwin.minimal
      ];

      # TODO: impl darwinModules.my.maintenance
      # my.maintenance.autoUpdate = true;
      # my.maintenance.autoClean = true;
    };
}
