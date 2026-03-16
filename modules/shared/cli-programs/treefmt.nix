# Multi-language code formatter (treefmt wrapped with nixfmt, stylua, prettier, etc.)
{
  flake.homeModules.cli-programs =
    { self, pkgs, ... }:
    {
      home.packages = [
        self.formatter.${pkgs.stdenv.hostPlatform.system}
        pkgs.prettier
      ];
    };
}
