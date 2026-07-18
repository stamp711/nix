{ self, ... }:
{
  flake.homeModules.personal =
    { config, pkgs, ... }:
    let
      s = self.lib.mkAgeSecret config ./wakatime.cfg.age;
    in
    {
      age.secrets = s.ageSecret;
      home.file.".wakatime.cfg".source = config.lib.file.mkOutOfStoreSymlink s.path;
      home.packages = [ pkgs.wakatime-cli ];
    };
}
