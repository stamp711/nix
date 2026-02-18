{
  # Home-manager hosts using this module must set `age.rekey.hostPubkey`.
  description = "agenix-rekey with shared master identity (home-manager)";

  module =
    { inputs, self, ... }:
    {
      imports = [
        inputs.agenix.homeManagerModules.default
        # TODO: use inputs.agenix-rekey.homeManagerModules.default once
        # https://github.com/oddlama/agenix-rekey/pull/143 is merged
        (import "${inputs.agenix-rekey}/modules/agenix-rekey.nix" inputs.nixpkgs)
      ];

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
