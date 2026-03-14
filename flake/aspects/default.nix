{ import-dir, ... }:
{
  flake.aspects = import-dir ./. { };
}
