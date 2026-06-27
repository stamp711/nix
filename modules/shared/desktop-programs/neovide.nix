# Neovide GUI wrapper: `nvide` drives the nixvim nvim.
{
  flake.homeModules.desktop-programs = { config, pkgs, ... }: {
    home.packages = [
      pkgs.neovide
      (pkgs.writeShellApplication {
        name = "nvide";
        runtimeInputs = [ pkgs.neovide ];
        text = ''
          exec neovide --neovim-bin ${config.programs.nixvim.build.package}/bin/nvim "$@"
        '';
      })
    ];
  };
}
