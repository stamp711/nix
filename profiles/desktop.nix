{ self, ... }:
{
  flake.profiles.nixos.desktop = {
    imports = [
      self.profiles.nixos.headless
      self.nixosModules.networking
      self.nixosModules.desktop-environment
      self.nixosModules.desktop-programs
    ];

  };

  flake.profiles.homeManager.desktop = {
    imports = [
      self.profiles.homeManager.headless
      self.homeModules.desktop-environment
      self.homeModules.desktop-programs
    ];
  };

  flake.profiles.darwin.desktop = {
    imports = [
      self.profiles.darwin.headless
      self.darwinModules.desktop-environment
      self.darwinModules.desktop-programs
    ];
  };
}
