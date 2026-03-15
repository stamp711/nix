{
  flake.profiles.homeManager.minimal =
    { self, ... }:
    {
      imports = [
        self.homeModules.core
        self.homeModules.my
        self.homeModules.shell
      ];
    };

  flake.profiles.nixos.minimal =
    { self, ... }:
    {
      imports = [
        self.nixosModules.core
        self.nixosModules.my
      ];
    };

  flake.profiles.darwin.minimal =
    { self, ... }:
    {
      imports = [
        self.darwinModules.core
        self.darwinModules.my
      ];
    };
}
