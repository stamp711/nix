# wakatime: track agent time/token usage. Source shared with the operator, rekeyed to the container key.
{ self, ... }:
{
  flake.homeModules.agent-sandbox =
    { config, pkgs, ... }:
    let
      waka = self.lib.mkAgeSecret config ../personal/wakatime/wakatime.cfg.age;
    in
    {
      age.secrets = waka.ageSecret;
      home.file.".wakatime.cfg".source = config.lib.file.mkOutOfStoreSymlink waka.path;
      home.packages = [ pkgs.wakatime-cli ];
    };
}
