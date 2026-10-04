# Use the mux for the CLI, including a stable proxy for forwarded agents.
{ lib, ... }:
{
  flake.homeModules.cli-environment =
    { config, pkgs, ... }:
    let
      sshForwardedSocket = "${config.home.homeDirectory}/.ssh/ssh-agent-switcher.sock";

      switcherStartupScript =
        let
          switcherPackage = pkgs.ssh-agent-switcher.overrideAttrs { doCheck = false; };
        in
        # - Remove stale sockets after crashes.
        # - Share permissions and cleanup across systemd and launchd.
        pkgs.writeShellScript "ssh-agent-switcher" ''
          set -e
          umask 077
          ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg (builtins.dirOf sshForwardedSocket)}
          ${pkgs.coreutils}/bin/rm -f ${lib.escapeShellArg sshForwardedSocket}
          exec ${lib.getExe switcherPackage} --socket-path ${lib.escapeShellArg sshForwardedSocket}
        '';
    in
    {
      my.ssh-agent-mux = {
        enable = true;
        sockets = lib.mkAfter [ sshForwardedSocket ];
      };

      systemd.user.services.ssh-agent-switcher = {
        Service = {
          ExecStart = toString switcherStartupScript;
          Restart = "on-failure";
          RestartSec = 1;
        };
        Install.WantedBy = [ "default.target" ];
      };

      launchd.agents.ssh-agent-switcher = {
        enable = true;
        domain = "user";
        config = {
          ProgramArguments = [ (toString switcherStartupScript) ];
          RunAtLoad = true;
          KeepAlive = true;
        };
      };
    };
}
