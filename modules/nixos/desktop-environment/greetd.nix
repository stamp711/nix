{
  flake.nixosModules.desktop-environment =
    { config, pkgs, ... }:
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

      # tuigreet's --remember persists last-login user/session here.
      # greeter user/group are fresh-install safety (no-op on migration).
      my.persistence.directories = [
        {
          directory = "/var/cache/tuigreet";
          user = "greeter";
          group = "greeter";
        }
      ];
    };
}
