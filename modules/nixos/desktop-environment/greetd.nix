{
  flake.nixosModules.desktop-environment =
    { pkgs, config, ... }:
    let
      sessions = config.services.displayManager.sessionData.desktops;
    in
    {
      services.greetd = {
        enable = true;
        useTextGreeter = true;
        settings.default_session.command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --asterisks \
            --remember \
            --remember-session \
            --sessions ${sessions}/share/wayland-sessions
        '';
      };
    };
}
