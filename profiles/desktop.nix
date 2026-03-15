{
  flake.profiles.nixos.desktop =
    { self, ... }:
    {
      imports = [
        self.profiles.nixos.headless
        self.nixosModules.common-hardware
        self.nixosModules.gnome
        self.nixosModules.audio
        self.nixosModules.networking
        self.nixosModules.solaar
        self.nixosModules.onepassword
      ];

    };

  flake.profiles.homeManager.desktop =
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
      imports = [ self.profiles.darwin.minimal ];
    };
}
