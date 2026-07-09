# NAS SMB shares, mounted on demand via systemd automount.
{ self, lib, ... }: {
  flake.nixosModules.nas-smb-mounts =
    { config, ... }:
    let
      shares = [
        "home"
        "Dropbox"
        "Z"
      ];
      secretName = self.lib.ageSecretName ./nas-smb.age;
      primaryUser = config.users.users.${config.my.primaryUser};
    in
    {
      # mount.cifs credentials format
      age.secrets.${secretName}.rekeyFile = ./nas-smb.age;

      fileSystems = lib.listToAttrs (
        map (share: {
          name = "/mnt/nas/${share}";
          value = {
            device = "//synology.boar-char.ts.net/${share}";
            fsType = "cifs";
            options = [
              "credentials=${config.age.secrets.${secretName}.path}"
              "vers=3.1.1"
              "uid=${toString primaryUser.uid}"
              "gid=${toString config.users.groups.${primaryUser.group}.gid}"
              "file_mode=0644"
              "dir_mode=0755"
              "iocharset=utf8"
              "ro"
              "nofail"
              "noauto"
              "x-systemd.automount"
              # mount attempt on access fails after this (default 90s)
              "x-systemd.mount-timeout=10s"
              # auto-unmount when untouched this long (default: never)
              "x-systemd.idle-timeout=5min"
              "x-gvfs-show"
              "x-gvfs-name=NAS%20${share}"
            ];
          };
        }) shares
      );
    };
}
