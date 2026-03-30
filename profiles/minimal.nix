{ self, ... }:
{
  flake.profiles.homeManager.minimal = {
    imports = [
      self.homeModules.core
      self.homeModules.my
    ];
  };

  flake.profiles.nixos.minimal = {
    imports = [
      self.nixosModules.core
      self.nixosModules.my
    ];
  };

  flake.profiles.darwin.minimal = {
    imports = [
      self.darwinModules.core
      self.darwinModules.my
    ];
  };

  flake.profiles.systemManager.minimal = {
    imports = [
      self.systemModules.core
    ];
  };
}
