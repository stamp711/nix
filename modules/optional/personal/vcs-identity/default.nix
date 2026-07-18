# Personal git/jj identity and GitHub push remotes.
{ self, ... }:
{
  flake.homeModules.personal =
    { lib, config, ... }:
    let
      mkAgeSecret =
        file:
        let
          name = self.lib.ageSecretName file;
        in
        {
          inherit name;
          inherit (config.age.secrets.${name}) path;
          rekey.${name}.rekeyFile = file;
        };

      gitIdentity = mkAgeSecret ./git.personal-identity.ini.age;
      jjIdentity = mkAgeSecret ./jj.personal-identity.toml.age;

      ghqRoot = config.programs.git.settings.ghq.root;
    in
    lib.mkMerge [
      (lib.mkIf config.programs.git.enable {
        programs.git.settings.ghq.user = "stamp711";
        age.secrets = gitIdentity.rekey;
        programs.git.includes = [
          {
            inherit (gitIdentity) path;
            condition = "gitdir:${ghqRoot}/github.com/";
          }
        ];
      })

      (lib.mkIf config.programs.jujutsu.enable {
        programs.jujutsu.settings."--scope" = [
          {
            "--when".repositories = [ "${ghqRoot}/github.com" ];
            git.push = "stamp711";
          }
          {
            "--when".repositories = [ "${ghqRoot}/github.com/stamp711" ];
            git.push = "origin";
          }
        ];
        age.secrets = jjIdentity.rekey;
        xdg.configFile."jj/conf.d/identity.toml".source =
          config.lib.file.mkOutOfStoreSymlink jjIdentity.path;
      })
    ];
}
