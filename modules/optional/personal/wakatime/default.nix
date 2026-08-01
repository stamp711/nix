{ lib, self, ... }:
{
  flake.homeModules.personal-wakatime =
    { config, pkgs, ... }:
    let
      s = self.lib.mkAgeSecret config ./wakatime-api-key.age;
      home = config.home.homeDirectory;
      ghqRoot = lib.replaceStrings [ "~" ] [ home ] config.programs.git.settings.ghq.root;
    in
    {
      home.packages = [ pkgs.wakatime-cli ];
      age.secrets = s.ageSecret;
      home.file.".wakatime.cfg".text = /* ini */ ''
        [settings]
        api_key_vault_cmd = ${pkgs.coreutils}/bin/cat ${s.path}
        # exclude raft.build agent notes
        exclude = /[.]slock/agents/
        # name the project after the repo, not after whoever edited it
        [projectmap]
        ^${ghqRoot}/[^/]+/[^/]+/([^/]+) = {0}
        ^${home}/agents/[^/]+/[^/]+/[^/]+/([^/]+) = {0}
      '';
    };

  flake.homeModules.personal.imports = [ self.homeModules.personal-wakatime ];
}
