{ self, ... }:
{
  flake.profiles.homeManager.headless = {
    imports = [
      self.profiles.homeManager.minimal
      self.homeModules.cli-environment
      self.homeModules.cli-programs
    ];

    my.maintenance.autoUpdate = true;
    my.maintenance.autoClean = true;
  };

  flake.profiles.nixos.headless = {
    imports = [
      self.profiles.nixos.minimal
      self.nixosModules.cli-environment
      self.nixosModules.hardware
      self.nixosModules.cli-programs
    ];

    my.maintenance.autoUpdate = true;
    my.maintenance.autoClean = true;
  };

  flake.profiles.darwin.headless = {
    imports = [
      self.profiles.darwin.minimal
      self.darwinModules.cli-environment
    ];

    # TODO: impl darwinModules.my.maintenance
    # my.maintenance.autoUpdate = true;
    # my.maintenance.autoClean = true;
  };
}
