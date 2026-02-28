{ import-dir, inputs, ... }:
{
  imports = [ inputs.home-manager.flakeModules.home-manager ];
  flake.homeModules = import-dir ./. { };
}
