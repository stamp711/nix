{
  flake.homeModules.desktop =
    { config, ... }:
    {
      home.packages = [ config.programs.t3code.package.desktop ];
    };
}
