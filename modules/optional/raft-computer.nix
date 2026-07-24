# raft.build daemon.
{ self, ... }:
{
  flake.homeModules.raft-computer =
    { pkgs, ... }:
    let
      pkg = self.packages.${pkgs.stdenv.hostPlatform.system}.raft-computer;
    in
    {
      home.packages = [ pkg ];
      systemd.user.services.raft-computer = {
        Install.WantedBy = [ "default.target" ];
        Service = {
          ExecStart = "${pkg}/bin/raft-computer __service --os-supervised systemd-user";
          Restart = "always";
          RestartSec = 5;
        };
      };
    };
}
