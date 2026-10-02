{
  flake.homeModules.desktop-linux =
    { config, ... }:
    {
      programs.ashell = {
        enable = true;
        systemd.enable = true;
      };

      systemd.user.services.ashell.Unit = {
        # Keep ashell out of GNOME while both desktop sessions are available.
        ConditionEnvironment = "XDG_CURRENT_DESKTOP=niri";
        # The upstream module does not stop the service when the session ends.
        PartOf = [ config.programs.ashell.systemd.target ];
      };
    };
}
