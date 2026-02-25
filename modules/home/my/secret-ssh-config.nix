{
  description = "SSH with agenix-rekey managed secret host configs";

  module =
    {
      self,
      config,
      lib,
      ...
    }:
    let
      cfg = config.my.ssh;
      secretNames = map self.lib.ageSecretName cfg.secretConfigFiles;
      decryptedPaths = map (n: config.age.secrets.${n}.path) secretNames;
    in
    {
      options.my.ssh.secretConfigFiles = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        description = "List of .age files containing secret SSH config snippets to include";
      };

      config = lib.mkIf (cfg.secretConfigFiles != [ ]) {
        programs.ssh.includes = decryptedPaths;

        age.secrets = lib.listToAttrs (
          lib.zipListsWith (name: file: {
            inherit name;
            value.rekeyFile = file;
          }) secretNames cfg.secretConfigFiles
        );
      };
    };
}
