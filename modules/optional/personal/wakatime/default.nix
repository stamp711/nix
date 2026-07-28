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
      home.file.".wakatime.cfg".text = ''
        [settings]
        # the key is the only secret here, so the rest can stay in the store
        api_key_vault_cmd = ${pkgs.coreutils}/bin/cat ${s.path}
        # exclude raft.build agent notes
        exclude = /[.]slock/agents/
      '';
    };

  flake.homeModules.personal.imports = [ self.homeModules.personal-wakatime ];
}
