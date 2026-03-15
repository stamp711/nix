{
  flake.profiles.nixos.desktop =
    { self, ... }:
    {
      imports = [
        self.profiles.nixos.headless
        self.nixosModules.networking
        self.nixosModules.desktop-environment
        self.nixosModules.desktop-apps
      ];

    };

  flake.profiles.homeManager.desktop-linux =
    { self, ... }:
    {
      imports = [
        self.profiles.homeManager.headless
        self.homeModules.desktop-environment
        self.homeModules.desktop-apps
      ];
    };

  flake.profiles.homeManager.desktop-darwin =
    { self, ... }:
    {
      imports = [
        self.profiles.homeManager.headless
        self.homeModules.desktop-apps
      ];
    };

  flake.profiles.darwin.desktop =
    { self, ... }:
    {
      imports = [
        self.profiles.darwin.minimal
        self.darwinModules.desktop-environment
      ];
    };
}
