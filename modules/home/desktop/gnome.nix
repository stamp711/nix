{
  description = "GNOME desktop preferences via dconf";

  module = {
    dconf.settings."org/gnome/desktop/peripherals/keyboard" = {
      delay = 225;
      repeat-interval = 15;
    };
  };
}
