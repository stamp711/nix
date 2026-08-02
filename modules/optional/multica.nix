# Multica agent daemon. Needs a one-time `multica login`, token lands in ~/.multica.
{ self, ... }:
{
  flake.homeModules.multica =
    { pkgs, ... }:
    let
      pkg = self.packages.${pkgs.stdenv.hostPlatform.system}.multica;
    in
    {
      home.packages = [ pkg ];
      systemd.user.services.multica = {
        Install.WantedBy = [ "default.target" ];
        # Untokened it exits and Restart spins.
        Unit.ConditionPathExists = "%h/.multica/config.json";
        Service = {
          # --foreground: it forks into the background otherwise.
          # --no-auto-update: it replaces its own binary, which here is in the store.
          ExecStart = "${pkg}/bin/multica daemon start --foreground --no-auto-update";
          Restart = "always";
          RestartSec = 5;
        };
      };
    };
}
