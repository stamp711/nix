let
  agePubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHdOxmUp8REg9IBoipLV40VYmLNiD6+TUUHb/ofyor60 ssh-age";

  # Hosts using this module must set `age.rekey.hostPubkey`.
  rekeyConfig = self: {
    masterIdentities = [
      {
        identity = "${self}/ssh-age.pub";
        pubkey = agePubKey;
      }
    ];
    storageMode = "local";
    localStorageDir = "${self}/.rekey";
  };
in
{
  flake.nixosModules.core =
    { self, ... }:
    {
      age.rekey = rekeyConfig self;
    };

  flake.homeModules.core =
    { self, config, ... }:
    {
      age.rekey = rekeyConfig self;
      # Default secretsDir is a shell expression, override with a literal path instead.
      # It's only a symlink, the actual secrets are still in an ephemeral runtime dir.
      age.secretsDir = "${config.xdg.dataHome}/agenix";
    };
}
