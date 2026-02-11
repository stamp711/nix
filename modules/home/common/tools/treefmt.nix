{
  description = "Multi-language code formatter (treefmt wrapped with nixfmt, stylua, prettier, etc.)";

  module =
    { self, pkgs, ... }:
    {
      home.packages = [
        self.formatter.${pkgs.stdenv.hostPlatform.system}
      ];
    };
}
