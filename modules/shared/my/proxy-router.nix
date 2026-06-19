# mihomo proxy router: stable local HTTP+SOCKS endpoint with domain-based routing + health-checked fallback.
# Runs as a user service: systemd on Linux, launchd on macOS.
{
  flake.homeModules.my =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.proxyRouter;
      configDir = "${config.xdg.configHome}/mihomo";

      proxyType = lib.types.submodule {
        freeformType = lib.types.attrsOf lib.types.anything;
        options = {
          type = lib.mkOption {
            type = lib.types.str;
            description = "Proxy type (socks5, http, ...).";
          };
          server = lib.mkOption {
            type = lib.types.str;
            description = "Upstream host.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            description = "Upstream port.";
          };
        };
      };

      groupType = lib.types.submodule {
        options = {
          proxies = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Member proxy names, in priority (fallback) order.";
          };
          url = lib.mkOption {
            type = lib.types.str;
            description = "Health-check URL — must be reachable by every member of the group.";
          };
          interval = lib.mkOption {
            type = lib.types.int;
            default = 60;
            description = "Health-check interval in seconds.";
          };
        };
      };

      # attrsOf submodule (keyed by name) -> mihomo's list-with-name form
      named = lib.mapAttrsToList (name: v: { inherit name; } // removeAttrs v [ "_module" ]);

      # the two fixed routing groups -> mihomo proxy-group entries
      mkGroup = gname: {
        name = gname;
        type = "fallback";
        inherit (cfg.fallbackProxyGroups.${gname}) proxies url interval;
      };

      settings = {
        mixed-port = cfg.port;
        mode = "rule";
        log-level = "warning";
        proxies = named cfg.proxies;
        proxy-groups = [
          (mkGroup "native")
          (mkGroup "auto")
        ];
        rules =
          (map (
            c: "${if lib.hasInfix ":" c then "IP-CIDR6" else "IP-CIDR"},${c},DIRECT,no-resolve"
          ) cfg.directIPs)
          ++ (map (d: "DOMAIN-SUFFIX,${d},DIRECT") cfg.directDomains)
          ++ (map (d: "DOMAIN-SUFFIX,${d},native") cfg.nativeDomains)
          ++ [ "MATCH,auto" ];
      }
      // lib.optionalAttrs (cfg.externalController != null) {
        external-controller = cfg.externalController;
      };

      mihomoConfig = (pkgs.formats.yaml { }).generate "mihomo.yaml" settings;

      # loopback is always direct; direct domains bypass the router too
      noProxy = lib.concatStringsSep "," (
        [
          "localhost"
          "127.0.0.1"
          "::1"
        ]
        ++ cfg.directDomains
      );

    in
    {
      options.my.proxyRouter = {
        enable = lib.mkEnableOption "mihomo proxy router";
        port = lib.mkOption {
          type = lib.types.port;
          default = 7890;
          description = "Local mixed HTTP+SOCKS port the shell points at.";
        };
        externalController = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Bind addr for mihomo's REST control/observability API (e.g. \"127.0.0.1:9090\"); null = off. Unauthenticated — keep it loopback.";
        };
        proxies = lib.mkOption {
          default = { };
          description = "mihomo proxies (upstreams), keyed by name. Type-specific keys pass through.";
          type = lib.types.attrsOf proxyType;
        };
        fallbackProxyGroups = lib.mkOption {
          default = { };
          description = "The two fallback proxy-groups: nativeDomains -> native, everything else -> auto.";
          type = lib.types.submodule {
            options = {
              native = lib.mkOption {
                type = groupType;
                description = "Group for nativeDomains; every member should be a proxy (no direct).";
              };
              auto = lib.mkOption {
                type = groupType;
                description = "Default group for everything else (MATCH).";
              };
            };
          };
        };
        nativeDomains = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "DOMAIN-SUFFIX domains routed via the 'native' group.";
        };
        directDomains = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "DOMAIN-SUFFIX domains forced DIRECT, and added to no_proxy so the shell bypasses the router too.";
        };
        directIPs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "IP-CIDR ranges forced DIRECT (no-resolve); e.g. LAN/loopback/tailnet. Not added to no_proxy (CIDR there is unreliable).";
        };
        enableZshIntegration = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Export http(s)_proxy / all_proxy / no_proxy pointing at the router in zsh.";
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            home.packages = [ pkgs.mihomo ];
            assertions =
              let
                known = lib.attrNames cfg.proxies ++ [
                  "DIRECT"
                  "REJECT"
                  "REJECT-DROP"
                  "PASS"
                  "COMPATIBLE"
                ];
                check =
                  gname:
                  let
                    ps = cfg.fallbackProxyGroups.${gname}.proxies;
                    undefined = lib.subtractLists known ps;
                    dups = lib.filter (p: lib.count (x: x == p) ps > 1) (lib.unique ps);
                  in
                  {
                    assertion = undefined == [ ] && dups == [ ];
                    message =
                      "my.proxyRouter.fallbackProxyGroups.${gname}.proxies: "
                      +
                        lib.optionalString (undefined != [ ])
                          "undefined members ${lib.concatStringsSep ", " undefined} (each must be a key in my.proxyRouter.proxies or a built-in like DIRECT). "
                      + lib.optionalString (dups != [ ]) "duplicate members ${lib.concatStringsSep ", " dups}.";
                  };
              in
              [
                (check "native")
                (check "auto")
              ];
          }

          (lib.mkIf cfg.enableZshIntegration {
            programs.zsh.initContent = ''
              export {http,https}_proxy="http://127.0.0.1:${toString cfg.port}"
              export {HTTP,HTTPS}_PROXY="http://127.0.0.1:${toString cfg.port}"
              export {all_proxy,ALL_PROXY}="socks5h://127.0.0.1:${toString cfg.port}"
              export {no_proxy,NO_PROXY}="${noProxy}"
            '';
          })

          (lib.mkIf pkgs.stdenv.isLinux {
            systemd.user.services.mihomo = {
              Unit = {
                Description = "mihomo proxy router";
                After = [ "network.target" ];
              };
              Install.WantedBy = [ "default.target" ];
              Service = {
                ExecStart = "${pkgs.mihomo}/bin/mihomo -d ${configDir} -f ${mihomoConfig}";
                Restart = "on-failure";
                RestartSec = 5;
              };
            };
          })

          (lib.mkIf pkgs.stdenv.isDarwin {
            launchd.agents.mihomo = {
              enable = true;
              config = {
                ProgramArguments = [
                  "${pkgs.mihomo}/bin/mihomo"
                  "-d"
                  configDir
                  "-f"
                  "${mihomoConfig}"
                ];
                RunAtLoad = true;
                KeepAlive = true;
              };
            };
          })
        ]
      );
    };
}
