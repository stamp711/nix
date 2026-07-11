# Multi-language code formatter (treefmt wrapped with nixfmt, stylua, prettier, etc.)
{
  flake.homeModules.cli-programs = { pkgs, ... }: {
    home.packages = with pkgs; [
      treefmt
      prettier
    ];
  };
}
