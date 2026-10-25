# SMB shares, mounted on demand via systemd automount.
{ lib, self, ... }:
{
  flake.nixosModules.my =
    { config, ... }:
    let
      cfg = config.my.smbMounts;
      primaryUser = config.users.users.${config.my.primaryUser};
    in
    {
      options.my.smbMounts = lib.mkOption {
        default = { };
        description = "SMB servers whose shares are automounted under {option}`mountBase`.";
        type = lib.types.attrsOf (
          lib.types.submodule (
            { name, ... }:
            {
              options = {
                server = lib.mkOption {
                  type = lib.types.str;
                  description = "SMB host to mount from.";
                };
                credentialsFile = lib.mkOption {
                  type = lib.types.path;
                  description = "File in mount.cifs credentials format.";
                };
                mountBase = lib.mkOption {
                  type = lib.types.str;
                  default = "/mnt/${name}";
                  description = "Where this server's shares are mounted.";
                };
                label = lib.mkOption {
                  type = lib.types.str;
                  default = name;
                  description = "Prefix for the name shown in file managers.";
                };
                shares = lib.mkOption {
                  default = { };
                  type = lib.types.attrsOf (
                    lib.types.submodule {
                      options.rw = lib.mkOption {
                        type = lib.types.bool;
                        default = false;
                        description = "Mount read-write. Read-only by default.";
                      };
                      options.mountOptions = lib.mkOption {
                        type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.bool);
                        default = { };
                        example = {
                          dir_mode = "0775";
                          "x-systemd.idle-timeout" = "0";
                          "x-systemd.requires" = "tailscaled.service";
                        };
                        description = ''
                          Add mount options or override defaults for this share.
                          A string produces `name=value`.
                          `true` adds the option name without a value.
                          `false` removes the option.
                        '';
                      };
                    }
                  );
                  description = "Shares to mount, keyed by their name on the server.";
                };
              };
            }
          )
        );
      };

      config.fileSystems = lib.listToAttrs (
        lib.concatLists (
          lib.mapAttrsToList (
            _: server:
            lib.mapAttrsToList (
              share: shareCfg:
              let
                defaultMountOptions = {
                  credentials = toString server.credentialsFile;
                  vers = "3.1.1";
                  uid = toString primaryUser.uid;
                  gid = toString config.users.groups.${primaryUser.group}.gid;
                  file_mode = "0664";
                  dir_mode = "0775";
                  iocharset = "utf8";
                  inherit (shareCfg) rw;
                  ro = !shareCfg.rw;
                  nofail = true;
                  noauto = true;
                  "x-systemd.automount" = true;
                  "x-systemd.mount-timeout" = "10s";
                  "x-systemd.idle-timeout" = "5min";
                  "x-gvfs-show" = true;
                  "x-gvfs-name" = "${server.label}%20${share}";
                };
                mountOptions = self.lib.mergeDisjoint [
                  (builtins.removeAttrs defaultMountOptions (builtins.attrNames shareCfg.mountOptions))
                  shareCfg.mountOptions
                ];
              in
              {
                name = "${server.mountBase}/${share}";
                value = {
                  device = "//${server.server}/${share}";
                  fsType = "cifs";
                  options = lib.mapAttrsToList (name: value: if value == true then name else "${name}=${value}") (
                    lib.filterAttrs (_: value: value != false) mountOptions
                  );
                };
              }
            ) server.shares
          ) cfg
        )
      );
    };
}
