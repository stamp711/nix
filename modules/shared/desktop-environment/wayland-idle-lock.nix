{
  flake.nixosModules.desktop-environment =
    { pkgs, ... }:
    {
      # https://git.sr.ht/~whynothugo/systemd-lock-handler
      services.systemd-lock-handler.enable = true;

      # Pulled in by lock.target (from systemd-lock-handler).
      # --daemonize forks after the lock surface is up, so Type=forking gives a race-free pre-sleep handshake.
      systemd.user.services.swaylock = {
        description = "Screen locker for Wayland (swaylock)";

        # If swaylock exits cleanly, unlock the session:
        onSuccess = [ "unlock.target" ];
        # When lock.target is stopped, stops this too:
        partOf = [ "lock.target" ];
        # Delay lock.target until this service is ready:
        after = [ "lock.target" ];

        serviceConfig = {
          # systemd will consider this service started when swaylock forks...
          Type = "forking";
          # ... and swaylock will fork only after it has locked the screen.
          ExecStart = "${pkgs.swaylock}/bin/swaylock --daemonize";
          # If swaylock crashes, always restart it immediately:
          Restart = "on-failure";
          RestartSec = 0;
        };

        wantedBy = [ "lock.target" ];

        # Mutter (GNOME) doesn't expose ext-session-lock-v1; skip there.
        unitConfig.ConditionEnvironment = [
          "WAYLAND_DISPLAY"
          "!XDG_CURRENT_DESKTOP=GNOME"
        ];
      };

      security.pam.services.swaylock = { };
    };

  flake.homeModules.desktop-environment =
    { lib, pkgs, ... }:
    {
      config = lib.mkIf pkgs.stdenv.isLinux {
        # Handle ext-idle-notify-v1, emit logind Lock signal after idle.
        services.swayidle = {
          enable = true;
          timeouts = [
            {
              timeout = 600;
              command = "loginctl lock-session";
            }
          ];
        };
        # Mutter (GNOME) doesn't expose ext-idle-notify-v1; skip there.
        systemd.user.services.swayidle.Unit.ConditionEnvironment = lib.mkForce [
          "WAYLAND_DISPLAY"
          "!XDG_CURRENT_DESKTOP=GNOME"
        ];
      };
    };
}
