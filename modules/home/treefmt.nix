{ self, pkgs, ... }:
{
  home.packages = [
    self.formatter.${pkgs.stdenv.hostPlatform.system}
  ];
}
