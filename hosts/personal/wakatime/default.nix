{ self, ... }:
{
  flake.homeModules.wakatime =
    { config, ... }:
    let
      file = ./wakatime.cfg.age;
      name = self.lib.ageSecretName file;
    in
    {
      age.secrets.${name}.rekeyFile = file;

      home.file.".wakatime.cfg".source =
        config.lib.file.mkOutOfStoreSymlink
          config.age.secrets.${name}.path;
    };
}
