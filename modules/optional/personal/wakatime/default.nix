{ self, ... }:
{
  flake.homeModules.personal-wakatime =
    { config, pkgs, ... }:
    let
      s = self.lib.mkAgeSecret config ./wakatime-api-key.age;
    in
    {
      home.packages = [ pkgs.wakatime-cli ];
      age.secrets = s.ageSecret;
      home.file.".wakatime.cfg".text = /* ini */ ''
        [settings]
        api_key_vault_cmd = ${pkgs.coreutils}/bin/cat ${s.path}
        # exclude raft.build agent notes
        exclude = /[.]slock/agents/
        [projectmap]
        ^/home/stamp/code/[^/]+/[^/]+/([^/]+) = {0}
        ^/home/stamp/agents/[^/]+/[^/]+/[^/]+/([^/]+) = {0}
        ^/Users/Developer/stamp/code/[^/]+/[^/]+/([^/]+) = {0}
        ^/Users/Developer/stamp/agents/[^/]+/[^/]+/[^/]+/([^/]+) = {0}
      '';
    };

  flake.homeModules.personal.imports = [ self.homeModules.personal-wakatime ];
}
