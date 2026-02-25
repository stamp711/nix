{
  # Hosts using this module must set `age.rekey.hostPubkey`.
  description = "agenix-rekey with shared master identity";

  module =
    { self, ... }:
    {
      config.age.rekey = {
        masterIdentities = [
          {
            identity = "${self}/ssh-age.pub";
            pubkey = self.lib.sshPublicKeys.age;
          }
        ];
        storageMode = "local";
        localStorageDir = "${self}/.rekey";
      };
    };
}
