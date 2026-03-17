{ self, ... }:
{
  flake.homeModules.my =
    { lib, config, ... }:
    let
      sshCfg = config.my.ssh;
      sshSecretNames = map self.lib.ageSecretName sshCfg.secretConfigFiles;
      sshDecryptedPaths = map (n: config.age.secrets.${n}.path) sshSecretNames;

      zshCfg = config.my.zsh;
      zshSecretNames = map self.lib.ageSecretName zshCfg.secretEnvExtra;
      zshDecryptedPaths = map (n: config.age.secrets.${n}.path) zshSecretNames;
    in
    {
      options.my.ssh.secretConfigFiles = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        description = "List of .age files containing secret SSH config snippets to include";
      };

      options.my.zsh.secretEnvExtra = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        description = "List of .age shell env files to decrypt and source in zsh";
      };

      config = lib.mkMerge [
        (lib.mkIf (sshCfg.secretConfigFiles != [ ]) {
          programs.ssh.includes = sshDecryptedPaths;

          age.secrets = lib.listToAttrs (
            lib.zipListsWith (name: file: {
              inherit name;
              value.rekeyFile = file;
            }) sshSecretNames sshCfg.secretConfigFiles
          );
        })

        (lib.mkIf (zshCfg.secretEnvExtra != [ ]) {
          age.secrets = lib.listToAttrs (
            lib.zipListsWith (name: file: {
              inherit name;
              value.rekeyFile = file;
            }) zshSecretNames zshCfg.secretEnvExtra
          );

          programs.zsh.envExtra = lib.concatMapStringsSep "\n" (p: "source ${p}") zshDecryptedPaths;
        })
      ];
    };
}
