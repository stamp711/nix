{
  # Home-manager hosts using this module must set `age.rekey.hostPubkey`.
  description = "agenix-rekey with shared master identity (home-manager)";

  module =
    {
      inputs,
      self,
      config,
      ...
    }:
    {
      imports = [
        inputs.agenix.homeManagerModules.default
        # TODO: use inputs.agenix-rekey.homeManagerModules.default once
        # https://github.com/oddlama/agenix-rekey/pull/143 is merged
        (import "${inputs.agenix-rekey}/modules/agenix-rekey.nix" inputs.nixpkgs)
      ];

      # secretsDir is only a symlink to secretsMountPoint, which still
      # defaults to an ephemeral runtime dir. Override with a literal path
      # so consumers like SSH Include can reference secret paths directly
      # (the default uses a shell expression that only works in scripts).
      config.age.secretsDir = "${config.xdg.dataHome}/agenix";

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
