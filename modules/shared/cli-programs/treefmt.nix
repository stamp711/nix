# Multi-language code formatter (treefmt wrapped with nixfmt, stylua, prettier, etc.)
{ self, ... }:
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      home.packages = [
        self.formatter.${pkgs.stdenv.hostPlatform.system}
        pkgs.prettier
      ];
    };
}
