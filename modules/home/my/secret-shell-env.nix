{
  description = "Source agenix-rekey managed secret shell env files";

  module =
    {
      self,
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.zsh;
      secretNames = map self.lib.ageSecretName cfg.secretEnvExtra;
      decryptedPaths = map (n: config.age.secrets.${n}.path) secretNames;
    in
    {
      options.my.zsh.secretEnvExtra = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        description = "List of .age shell env files to decrypt and source in zsh";
      };

      config = lib.mkIf (cfg.secretEnvExtra != [ ]) {
        age.secrets = lib.listToAttrs (
          lib.zipListsWith (name: file: {
            inherit name;
            value.rekeyFile = file;
          }) secretNames cfg.secretEnvExtra
        );

        programs.zsh.envExtra = lib.concatMapStringsSep "\n" (p: "source ${p}") decryptedPaths;
      };
    };
}
