{ lib, self, ... }:
{
  flake.profiles.homeManager.headless =
    { config, ... }:
    {
      imports = [
        self.profiles.homeManager.minimal
        self.homeModules.cli-environment
        self.homeModules.cli-programs
      ];

      # NOTE: When embedded in a host, the host's own maintenance covers those.
      my.maintenance = lib.mkIf (!config.submoduleSupport.enable) {
        autoUpdate = lib.mkDefault true;
        autoClean = lib.mkDefault true;
      };
    };

  flake.profiles.nixos.headless = {
    imports = [
      self.profiles.nixos.minimal
      self.nixosModules.hardware
      self.nixosModules.networking
      self.nixosModules.cli-environment
      self.nixosModules.cli-programs
    ];

    my.maintenance.autoUpdate = lib.mkDefault true;
    my.maintenance.autoClean = lib.mkDefault true;
  };

  flake.profiles.darwin.headless = {
    imports = [
      self.profiles.darwin.minimal
      self.darwinModules.cli-environment
      self.darwinModules.cli-programs
    ];

    my.maintenance.autoUpdate = lib.mkDefault true;
    my.maintenance.autoClean = lib.mkDefault true;
  };

  flake.profiles.systemManager.headless = {
    imports = [
      self.profiles.systemManager.minimal
    ];
  };
}
