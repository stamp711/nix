# Multiplex SSH agents through a single socket.
{ lib, ... }:
{
  flake.homeModules.my =
    { config, pkgs, ... }:
    {
      options.my.ssh-agent-mux = {
        enable = lib.mkEnableOption "SSH agent multiplexing";

        sockets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "SSH agent sockets to include in the mux.";
        };
      };

      config =
        let
          muxSocket = "${config.home.homeDirectory}/.ssh/ssh-agent-mux.sock";

          muxStartupScript =
            let
              muxPackage = pkgs.ssh-agent-mux.overrideAttrs (old: {
                patches = (old.patches or [ ]) ++ [ ./ssh-agent-mux-ignore-unavailable.patch ];
              });
            in
            # - Remove stale sockets after crashes.
            # - Share permissions and cleanup across systemd and launchd.
            pkgs.writeShellScript "ssh-agent-mux" ''
              set -e
              umask 077
              ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg (builtins.dirOf muxSocket)}
              ${pkgs.coreutils}/bin/rm -f ${lib.escapeShellArg muxSocket}
              exec ${lib.getExe muxPackage} --listen ${
                lib.escapeShellArgs ([ muxSocket ] ++ lib.unique config.my.ssh-agent-mux.sockets)
              }
            '';
        in
        lib.mkIf config.my.ssh-agent-mux.enable {
          # Keep the mux selected even in SSH sessions.
          sshAuthSock.enable = lib.mkForce false;
          home.sessionVariables.SSH_AUTH_SOCK = muxSocket;
          programs.ssh.extraOptionOverrides.IdentityAgent = muxSocket;

          programs.zsh.envExtra = lib.mkAfter "export SSH_AUTH_SOCK=${lib.escapeShellArg muxSocket}";
          programs.bash.bashrcExtra = lib.mkBefore "export SSH_AUTH_SOCK=${lib.escapeShellArg muxSocket}";
          programs.fish.shellInit = lib.mkAfter "set -gx SSH_AUTH_SOCK ${lib.escapeShellArg muxSocket}";
          programs.nushell.extraEnv = lib.mkAfter "$env.SSH_AUTH_SOCK = ${builtins.toJSON muxSocket}";

          systemd.user = {
            sessionVariables.SSH_AUTH_SOCK = muxSocket;
            services.ssh-agent-mux = {
              Unit.Description = "Multiplex SSH agents";
              Service = {
                ExecStart = toString muxStartupScript;
                Restart = "on-failure";
                RestartSec = 1;
              };
              Install.WantedBy = [ "default.target" ];
            };
          };

          launchd.agents = {
            ssh-agent-mux = {
              enable = true;
              domain = "user";
              config = {
                ProgramArguments = [ (toString muxStartupScript) ];
                RunAtLoad = true;
                KeepAlive = true;
              };
            };

            # GUI apps inherit Apple's socket before shell configuration runs.
            ssh-agent-socket = {
              enable = true;
              domain = "gui";
              config = {
                ProgramArguments = [
                  "/bin/sh"
                  "-c"
                  ''
                    if [ -n "''${SSH_AUTH_SOCK:-}" ] && [ "$SSH_AUTH_SOCK" != ${lib.escapeShellArg muxSocket} ]; then
                      /bin/ln -sf ${lib.escapeShellArg muxSocket} "$SSH_AUTH_SOCK"
                    fi
                  ''
                ];
                RunAtLoad = true;
              };
            };
          };
        };
    };
}
