{ import-dir, ... }:
{
  imports = (import-dir ./. { collect = true; })._all;
}
