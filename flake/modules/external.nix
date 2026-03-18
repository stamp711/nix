{ inputs, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.flakeModules
    inputs.home-manager.flakeModules.home-manager
  ];
}
