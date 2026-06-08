{
  flake.nixosModules.desktop-environment =
    { config, pkgs, ... }:
    let
      sessions = config.services.displayManager.sessionData.desktops;
    in
    {
      # To switch: comment out greetd below, uncomment gdm.
      services.displayManager.gdm.enable = true;

      services.greetd = {
        enable = false;
        useTextGreeter = true;
        # Must be single-line, https://github.com/NixOS/nixpkgs/issues/527565
        settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --asterisks --remember --remember-session --sessions ${sessions}/share/wayland-sessions";
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
