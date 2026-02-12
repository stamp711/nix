{
  description = "GPD Pocket 4: common + hardware + GNOME desktop";

  module =
    { self, ... }:
    {
      imports = self.nixosModules.common._all ++ [
        self.nixosModules.hardware.gpd-pocket-4
        self.nixosModules.hardware.lte
        self.nixosModules.desktop.gnome
      ];
    };
}
