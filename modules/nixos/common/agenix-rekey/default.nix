{
  # Hosts using this module must set `age.rekey.hostPubkey`.
  description = "agenix-rekey with shared master identity";

  module =
    { inputs, self, ... }:
    {
      imports = [
        inputs.agenix.nixosModules.default
        inputs.agenix-rekey.nixosModules.default
        ./agenix-template.nix
      ];

      config.age.rekey = {
        masterIdentities = [
          {
            identity = "${self}/ssh-age.pub";
            pubkey = self.lib.sshPublicKeys.age;
          }
        ];
        storageMode = "local";
        localStorageDir = "${self}/agenix-rekey";
      };
    };
}
