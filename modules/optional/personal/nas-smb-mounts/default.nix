# Personal NAS shares; the mount mechanism lives in my/smb-mounts.nix.
{ self, ... }:
{
  flake.nixosModules.personal =
    { config, ... }:
    let
      # mount.cifs credentials format
      s = self.lib.mkAgeSecret config { rekeyFile = ./nas-smb.age; };
    in
    {
      age.secrets = s.ageSecret;
      my.smbMounts.nas = {
        server = "synology.boar-char.ts.net";
        credentialsFile = s.path;
        label = "NAS";
        shares = {
          home = { };
          Dropbox = { };
        };
      };
    };
}
