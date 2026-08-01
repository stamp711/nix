# Reuse personal git/jj identity in the sandbox.
{ self, ... }:
{
  flake.homeModules.agent-sandbox =
    { lib, config, ... }:
    let
      gitIdentity = self.lib.mkAgeSecret config {
        rekeyFile = ../personal/vcs-identity/git.personal-identity.ini.age;
      };
      jjIdentity = self.lib.mkAgeSecret config {
        rekeyFile = ../personal/vcs-identity/jj.personal-identity.toml.age;
      };
    in
    lib.mkMerge [
      (lib.mkIf config.programs.git.enable {
        age.secrets = gitIdentity.ageSecret;
        programs.git.includes = [ { inherit (gitIdentity) path; } ];
      })

      (lib.mkIf config.programs.jujutsu.enable {
        age.secrets = jjIdentity.ageSecret;
        xdg.configFile."jj/conf.d/identity.toml".source =
          config.lib.file.mkOutOfStoreSymlink jjIdentity.path;
      })
    ];
}
