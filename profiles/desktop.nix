{
  flake.profiles.nixos.desktop =
    { self, ... }:
    {
      imports = [
        self.profiles.nixos.headless
        self.nixosModules.networking
        self.nixosModules.desktop-environment
        self.nixosModules.desktop-programs
      ];

    };

  flake.profiles.homeManager.desktop =
    { self, ... }:
    {
      imports = [
        self.profiles.homeManager.headless
        self.homeModules.desktop-environment
        self.homeModules.desktop-programs
      ];
    };

  flake.profiles.darwin.desktop =
    { self, ... }:
    {
      imports = [
        self.profiles.darwin.headless
        self.darwinModules.desktop-environment
        self.darwinModules.desktop-programs
      ];
    };
}
