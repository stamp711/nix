{
  flake.homeModules.my =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.services.glider-proxy;

      # nixpkgs meta restricts glider to Linux but it builds fine on Darwin.
      glider = pkgs.glider.overrideAttrs (old: {
        meta = old.meta // {
          platforms = old.meta.platforms ++ lib.platforms.darwin;
        };
      });

      checkScript = pkgs.writeShellScript "glider-check" ''
        [[ $FORWARDER_URL = direct* ]] && exit 0
        exec ${pkgs.netcat}/bin/nc -z -w 2 \
          "''${FORWARDER_ADDR%:*}" "''${FORWARDER_ADDR##*:}"
      '';

      gliderArgs = [
        "-listen"
        ":${toString cfg.listenPort}"
        "-forward"
        "socks5://${cfg.upstream}#priority=100"
        "-forward"
        "direct#priority=1"
        "-strategy"
        "ha"
        "-check"
        "file://${checkScript}"
        "-checkinterval"
        "10"
        "-checkdisabledonly"
        "-maxfailures"
        "3"
      ];
    in
    {
      options.my.services.glider-proxy = {
        enable = lib.mkEnableOption "glider proxy with TCP-probe fallback to direct";

        upstream = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1:6153";
          description = "Upstream SOCKS5 proxy (host:port). Probed via plain TCP connect.";
        };

        listenPort = lib.mkOption {
          type = lib.types.port;
          default = 6154;
          description = "Local port glider exposes (mixed HTTP+SOCKS5).";
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          { home.packages = [ glider ]; }

          # ---- Linux: systemd user service ----
          (lib.mkIf pkgs.stdenv.isLinux {
            systemd.user.services.glider-proxy = {
              Unit.Description = "glider proxy with HA fallback to direct";
              Service = {
                ExecStart = "${glider}/bin/glider ${lib.escapeShellArgs gliderArgs}";
                Restart = "on-failure";
              };
              Install.WantedBy = [ "default.target" ];
            };
          })

          # ---- macOS: launchd agent ----
          (lib.mkIf pkgs.stdenv.isDarwin {
            launchd.agents.glider-proxy = {
              enable = true;
              config = {
                ProgramArguments = [ "${glider}/bin/glider" ] ++ gliderArgs;
                KeepAlive.SuccessfulExit = false;
              };
            };
          })
        ]
      );
    };
}
