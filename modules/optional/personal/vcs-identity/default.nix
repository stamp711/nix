# Personal git/jj identity and GitHub push remotes.
{ self, ... }:
{
  flake.homeModules.personal =
    { lib, config, ... }:
    let
      gitIdentity = self.lib.mkAgeSecret config { rekeyFile = ./git.personal-identity.ini.age; };
      jjIdentity = self.lib.mkAgeSecret config { rekeyFile = ./jj.personal-identity.toml.age; };
      ghqRoot = config.programs.git.settings.ghq.root;
    in
    lib.mkMerge [
      (lib.mkIf config.programs.git.enable {
        age.secrets = gitIdentity.ageSecret;
        programs.git.includes = [ { inherit (gitIdentity) path; } ];
        programs.git.settings.commit.gpgSign = true;
        programs.git.settings.ghq.user = "stamp711";
        programs.git.settings.url."ssh://git@github.com/".insteadOf = "https://github.com/";
      })

      (lib.mkIf config.programs.gh.enable {
        programs.gh.settings.git_protocol = "ssh";
      })

      (lib.mkIf config.programs.jujutsu.enable {
        age.secrets = jjIdentity.ageSecret;
        xdg.configFile."jj/conf.d/identity.toml".source =
          config.lib.file.mkOutOfStoreSymlink jjIdentity.path;
        programs.jujutsu.settings.signing.sign-all = true;
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
      })
    ];
}
