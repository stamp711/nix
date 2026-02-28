let
  # Hosts using this module must set `age.rekey.hostPubkey`.
  rekeyConfig = self: {
    masterIdentities = [
      {
        identity = "${self}/ssh-age.pub";
        pubkey = self.lib.sshPublicKeys.age;
      }
    ];
    storageMode = "local";
    localStorageDir = "${self}/.rekey";
  };
in
{
  nixos =
    { self, ... }:
    {
      age.rekey = rekeyConfig self;
    };

  homeManager =
    { self, config, ... }:
    {
      age.rekey = rekeyConfig self;
      # secretsDir is only a symlink to secretsMountPoint, which still
      # defaults to an ephemeral runtime dir. Override with a literal path
      # so consumers like SSH Include can reference secret paths directly
      # (the default uses a shell expression that only works in scripts).
      age.secretsDir = "${config.xdg.dataHome}/agenix";
    };
}
