{
  flake.nixosModules.logind =
    { pkgs, ... }:
    {
      services.logind.settings.Login = {
        HandleLidSwitchExternalPower = "lock"; # don't sleep on external power
        IdleAction = "lock";
        IdleActionSec = 600;
      };

      # Screen locker via waylock
      environment.systemPackages = [ pkgs.waylock ];
      # https://git.sr.ht/~whynothugo/systemd-lock-handler
      services.systemd-lock-handler.enable = true;
      systemd.user.services.waylock = {
        description = "Screen locker (waylock)";
        # If swaylock exits cleanly, unlock the session:
        onSuccess = [ "unlock.target" ];
        # When lock.target is stopped, stops this too:
        partOf = [ "lock.target" ];
        # Delay lock.target until this service is ready:
        after = [ "lock.target" ];
        serviceConfig = {
          Type = "forking";
          ExecStart = "${pkgs.waylock}/bin/waylock -fork-on-lock";
          Restart = "on-failure";
          RestartSec = 0;
        };
        wantedBy = [ "lock.target" ];
      };
    };
}
