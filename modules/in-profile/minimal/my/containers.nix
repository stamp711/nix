# Stable-identity nixos-containers: persisted home + /persist, own rekey identity, host's nix store.
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
      user = config.my.primaryUser;
      system = pkgs.stdenv.hostPlatform.system;
      group = config.users.users.${user}.group;
      hostName = config.networking.hostName;

      # Persist what we bind, not the parent, or the mount hides it.
      stateDirs = cfg: [
        {
          directory = "${cfg.statePath}/home";
          inherit user group;
          mode = "0700";
        }
        {
          # traversable: services running as the container user can keep state below it
          directory = "${cfg.statePath}/persist";
          mode = "0755";
        }
      ];

      # Ensure bind sources exist. Redundant with the above wherever my.persistence is on.
      dirRules =
        cfg:
        [ "d ${cfg.statePath} 0755 root root - -" ]
        ++ lib.mapAttrsToList (_: o: "d ${o.hostPath} ${o.mode} ${o.owner} ${o.group} - -") cfg.sharedDirs;

      mkContainer = name: cfg: {
        autoStart = true;
        ephemeral = true;
        privateNetwork = cfg.macvlan != null;
        macvlans = lib.optional (cfg.macvlan != null) cfg.macvlan;
        # owner, group and mode are ours. The rest of an entry is upstream's.
        bindMounts = lib.mapAttrs (
          _: o:
          removeAttrs o [
            "owner"
            "group"
            "mode"
          ]
        ) cfg.sharedDirs;

        config.imports =
          # HM
          lib.optionals (cfg.homeModules != [ ]) [
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${user}.imports =
                  self.lib.homeBaseModules
                  ++ cfg.homeModules
                  ++ lib.singleton {
                    age.rekey.hostPubkey = lib.mkIf (cfg.userPubkey != null) cfg.userPubkey;
                    age.rekey.localStorageDir = self.lib.rekeyDir "${hostName}-${name}-${user}";
                    my.primaryUser = user;
                  }
                  ++ lib.singleton {
                    my.maintenance = {
                      autoUpdate = false;
                      autoClean = false;
                    };
                  };
              };
            }
          ]

          # Networking
          ++ lib.singleton {
            networking.networkmanager.enable = lib.mkForce false;
            networking.hostName = "${hostName}-${name}";
          }
          ++ lib.optional (cfg.macvlan != null) {
            networking.useNetworkd = true;
            networking.useHostResolvConf = lib.mkForce false;
            systemd.network.networks."10-mv" = {
              matchConfig.Name = "mv-*";
              networkConfig.DHCP = "yes";
            };
          }

          # Container-specific
          ++ lib.singleton {
            # host owns GC/rebuilds for the shared store; never from inside
            my.maintenance = {
              autoUpdate = false;
              autoClean = false;
            };
            # use the host daemon, not a container-local one
            systemd.services.nix-daemon.enable = lib.mkForce false;
            systemd.sockets.nix-daemon.enable = lib.mkForce false;
          }

          ++ self.lib.nixosBaseModules {
            inherit system;
            rekey = cfg.hostPubkey != null;
          }
          ++ cfg.nixosModules
          ++ lib.optional (cfg.hostPubkey != null) {
            # decrypts its own secrets; identity = the persisted ssh host key (age.identityPaths, from core)
            age.rekey.hostPubkey = cfg.hostPubkey;
            age.rekey.localStorageDir = self.lib.rekeyDir "${hostName}-${name}";
          }
          ++ lib.singleton {
            my.primaryUser = user;
            users.users.${user}.openssh.authorizedKeys.keys = [ self.lib.sshPubKey ];
          };
      };
    in
    {
      options.my.containers = lib.mkOption {
        default = { };
        description = "Nixos-containers keyed by name; each gets /var/lib/<name> as its state root.";
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, config, ... }:
            {
              options = {
                statePath = lib.mkOption {
                  type = lib.types.path;
                  default = "/var/lib/${name}";
                  defaultText = lib.literalExpression ''"/var/lib/''${name}"'';
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
                sharedDirs = lib.mkOption {
                  default = { };
                  description = ''
                    Dirs the container shares with the host, keyed by their mount point
                    inside it. Each is created on the host with the owner, group and mode
                    given here, then bind-mounted. Everything but those three reaches
                    {option}`containers.<name>.bindMounts` as written.
                  '';
                  type = lib.types.attrsOf (
                    lib.types.submodule (
                      { name, ... }:
                      {
                        freeformType = lib.types.attrsOf lib.types.anything;
                        options = {
                          hostPath = lib.mkOption {
                            type = lib.types.str;
                            default = name;
                            defaultText = lib.literalExpression "the mount point it is keyed by";
                            description = "Where the dir lives on the host.";
                          };
                          isReadOnly = lib.mkOption {
                            type = lib.types.bool;
                            default = false;
                            description = ''
                              Whether the container may only read it. Upstream's own
                              default is `true`, and a dir shared with a container is
                              usually one it writes.
                            '';
                          };
                          owner = lib.mkOption {
                            type = lib.types.str;
                            default = user;
                            defaultText = lib.literalExpression "config.my.primaryUser";
                            description = "Owner of the directory on the host.";
                          };
                          group = lib.mkOption {
                            type = lib.types.str;
                            default = group;
                            defaultText = lib.literalExpression "the primary user's group";
                            description = "Group of the directory on the host.";
                          };
                          mode = lib.mkOption {
                            type = lib.types.str;
                            default = "0755";
                            description = "Mode of the directory on the host.";
                          };
                        };
                      }
                    )
                  );
                };
                nixosModules = lib.mkOption {
                  type = lib.types.listOf lib.types.deferredModule;
                  default = [ ];
                  description = "NixOS modules the container is built from; pass a profile here.";
                };
                homeModules = lib.mkOption {
                  type = lib.types.listOf lib.types.deferredModule;
                  default = [ ];
                  description = "Home-manager modules for the container user; empty means no home-manager.";
                };
                macvlan = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Host NIC to macvlan onto for the container; null keeps the shared host netns.";
                };
              };

              # These two merge with whatever the caller writes. An option's default
              # would be dropped whole as soon as the caller writes one entry.
              config.sharedDirs = {
                "/home/${user}" = {
                  hostPath = "${config.statePath}/home";
                  mode = "0700";
                };
                "/persist" = {
                  hostPath = "${config.statePath}/persist";
                  owner = "root";
                  group = "root";
                };
              };
            }
          )
        );
      };

      config = {
        my.persistence.directories = lib.concatMap stateDirs (lib.attrValues config.my.containers);
        systemd.tmpfiles.rules = lib.concatMap dirRules (lib.attrValues config.my.containers);
        containers = lib.mapAttrs mkContainer config.my.containers;
      };
    };
}
