{ lib, ... }:
{
  flake.nixosModules.core =
    { config, ... }:
    {
      services.earlyoom.enable = lib.mkDefault (!config.boot.isContainer);
    };
}
