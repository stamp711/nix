{ import-dir, ... }:
{
  flake.nixosModules = import-dir ./. { };
}
