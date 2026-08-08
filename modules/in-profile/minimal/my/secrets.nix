{ self, ... }:
{
  flake.homeModules.my =
    { config, lib, ... }:
    let
      sshCfg = config.my.ssh;
      zshCfg = config.my.zsh;
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
        (lib.mkIf (sshCfg.secretConfigFiles != [ ]) (
          let
            secretNames = map self.lib.ageSecretName sshCfg.secretConfigFiles;
          in
          {
            programs.ssh.includes = map (n: config.age.secrets.${n}.path) secretNames;

            age.secrets = lib.listToAttrs (
              lib.zipListsWith (name: file: {
                inherit name;
                value.rekeyFile = file;
              }) secretNames sshCfg.secretConfigFiles
            );
          }
        ))

        (lib.mkIf (zshCfg.secretEnvExtra != [ ]) (
          let
            secretNames = map self.lib.ageSecretName zshCfg.secretEnvExtra;
          in
          {
            age.secrets = lib.listToAttrs (
              lib.zipListsWith (name: file: {
                inherit name;
                value.rekeyFile = file;
              }) secretNames zshCfg.secretEnvExtra
            );

            programs.zsh.envExtra = lib.concatMapStringsSep "\n" (p: "source ${p}") (
              map (n: config.age.secrets.${n}.path) secretNames
            );
          }
        ))
      ];
    };
}
