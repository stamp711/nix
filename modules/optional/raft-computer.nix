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
          # tini adopts whatever detaches from an agent, so it keeps hanging under this unit in a process tree.
          # NOTE: stopping the unit already killed it either way, by cgroup; this is about seeing whose it is.
          ExecStart = "${pkgs.tini}/bin/tini -s -- ${pkg}/bin/raft-computer __service --os-supervised systemd-user";
          Restart = "always";
          RestartSec = 5;
        };
      };
    };
}
