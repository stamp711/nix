{ self, ... }:
{
  flake.profiles.homeManager.desktop = {
    imports = [
      self.profiles.homeManager.headless
      self.homeModules.desktop
    ];
  };

  flake.profiles.nixos.desktop-linux = {
    imports = [
      self.profiles.nixos.headless
      self.nixosModules.desktop-linux
    ];
  };

  flake.profiles.homeManager.desktop-linux = {
    imports = [
      self.profiles.homeManager.desktop
      self.homeModules.desktop-linux
    ];
  };

  flake.profiles.darwin.desktop-darwin = {
    imports = [
      self.profiles.darwin.headless
      self.darwinModules.desktop-darwin
    ];
  };

  flake.profiles.homeManager.desktop-darwin = {
    imports = [
      self.profiles.homeManager.desktop
      self.homeModules.desktop-darwin
    ];
  };
}
