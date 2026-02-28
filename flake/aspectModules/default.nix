{ import-dir, ... }:
{
  flake.aspectModules = import-dir ./. { };
}
