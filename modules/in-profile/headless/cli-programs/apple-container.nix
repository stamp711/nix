{
  flake.homeModules.cli-programs =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.isDarwin {
      # xdg.configFile."container/config.toml" = lib.mkIf pkgs.stdenv.isDarwin {
      #   source = (pkgs.formats.toml { }).generate "container-config.toml" {
      #     machine.homeMount = "none";
      #     dns.domain = "container";
      #   };
      # };
      programs.zsh.shellAliases."c" = "container";
    };
}
