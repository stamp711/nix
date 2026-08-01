# SMB shares, mounted on demand via systemd automount.
{ lib, ... }:
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
            lib.mapAttrsToList (share: shareCfg: {
              name = "${server.mountBase}/${share}";
              value = {
                device = "//${server.server}/${share}";
                fsType = "cifs";
                options = [
                  "credentials=${server.credentialsFile}"
                  "vers=3.1.1"
                  "uid=${toString primaryUser.uid}"
                  "gid=${toString config.users.groups.${primaryUser.group}.gid}"
                  "file_mode=0644"
                  "dir_mode=0755"
                  "iocharset=utf8"
                  (if shareCfg.rw then "rw" else "ro")
                  "nofail"
                  "noauto"
                  "x-systemd.automount"
                  # mount attempt on access fails after this (default 90s)
                  "x-systemd.mount-timeout=10s"
                  # auto-unmount when untouched this long (default: never)
                  "x-systemd.idle-timeout=5min"
                  "x-gvfs-show"
                  "x-gvfs-name=${server.label}%20${share}"
                ];
              };
            }) server.shares
          ) cfg
        )
      );
    };
}
