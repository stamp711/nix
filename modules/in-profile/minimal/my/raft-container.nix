# raft.build sandbox: headless NixOS + HM raft service in a stable-identity nixos-container.
{ inputs, self, ... }:
{
  flake.nixosModules.my =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.raft-container;
      user = config.my.primaryUser;
      system = pkgs.stdenv.hostPlatform.system;
      group = config.users.users.${user}.group;
      hostName = config.networking.hostName;
    in
    {
      options.my.raft-container = {
        enable = lib.mkEnableOption "Raft Computer sandbox container";
        statePath = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/raft";
          description = "Host dir persisted as the container's state root (home + /persist).";
        };
        hostPubkey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Container's ssh host pubkey for agenix-rekey; null until first boot generates the key.";
        };
        userPubkey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Container user's ~/.ssh/id_ed25519 pubkey for home-manager agenix-rekey.";
        };
        hostDirs = lib.mkOption {
          type = lib.types.listOf lib.types.path;
          default = [ ];
          description = "Host dirs bind-mounted rw into the container at the same path; created on the host if missing.";
        };
        extraModules = lib.mkOption {
          type = lib.types.listOf lib.types.deferredModule;
          default = [ ];
          description = "Extra NixOS modules for the container.";
        };
        extraHomeModules = lib.mkOption {
          type = lib.types.listOf lib.types.deferredModule;
          default = [ ];
          description = "Extra home-manager modules for the container user.";
        };
        macvlan = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Host NIC to macvlan onto for the container; null keeps the shared host netns.";
        };
      };

      config = lib.mkIf cfg.enable {
        my.persistence.directories = [ cfg.statePath ];
        systemd.tmpfiles.rules = [
          "d ${cfg.statePath} 0755 root root - -"
          "d ${cfg.statePath}/home 0700 ${user} ${group} - -"
          "d ${cfg.statePath}/persist 0700 root root - -"
        ]
        # Ensure bind sources exist.
        ++ map (d: "d ${d} 0755 ${user} ${group} - -") cfg.hostDirs;

        containers.raft = {
          autoStart = true;
          ephemeral = true;
          privateNetwork = cfg.macvlan != null;
          macvlans = lib.optional (cfg.macvlan != null) cfg.macvlan;
          bindMounts = {
            "/home/${user}" = {
              hostPath = "${cfg.statePath}/home";
              isReadOnly = false;
            };
            "/persist" = {
              hostPath = "${cfg.statePath}/persist";
              isReadOnly = false;
            };
          }
          // lib.listToAttrs (
            map (
              d:
              lib.nameValuePair d {
                hostPath = d;
                isReadOnly = false;
              }
            ) cfg.hostDirs
          );

          config = {

            imports =
              self.lib.nixosBaseModules {
                inherit system;
                rekey = true;
              }
              ++ cfg.extraModules
              ++ [
                self.profiles.nixos.headless
                inputs.home-manager.nixosModules.home-manager
              ]
              ++ lib.optional (cfg.macvlan != null) {
                networking.useNetworkd = true;
                networking.useHostResolvConf = lib.mkForce false;
                systemd.network.networks."10-mv" = {
                  matchConfig.Name = "mv-*";
                  networkConfig.DHCP = "yes";
                };
              };

            # use the host daemon, not a container-local one
            systemd.services.nix-daemon.enable = lib.mkForce false;
            systemd.sockets.nix-daemon.enable = lib.mkForce false;

            networking.networkmanager.enable = lib.mkForce false;

            # distinct hostname per host so LAN names don't collide
            networking.hostName = "raft-${hostName}";

            # decrypts its own secrets; identity = the persisted ssh host key (age.identityPaths, from core)
            age.rekey.hostPubkey = lib.mkIf (cfg.hostPubkey != null) cfg.hostPubkey;

            # host owns GC/rebuilds for the shared store; never from inside
            my.maintenance = {
              autoUpdate = false;
              autoClean = false;
            };

            my.primaryUser = user;
            users.users.${user}.openssh.authorizedKeys.keys = [ self.lib.sshPubKey ];

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user} = {
                my.primaryUser = user;
                my.maintenance = {
                  autoUpdate = false;
                  autoClean = false;
                };
                age.rekey.hostPubkey = lib.mkIf (cfg.userPubkey != null) cfg.userPubkey;
                imports = self.lib.homeBaseModules { rekey = true; } ++ [
                  self.profiles.homeManager.headless
                  self.homeModules.raft-computer
                  self.homeModules.agent-sandbox
                  self.homeModules.github-ratelimit-token
                ];
              };
            };

          };

        };
      };
    };
}
