# Neovide GUI wrapper: `nvide` drives the nixvim nvim.
{
  flake.homeModules.desktop =
    { config, pkgs, ... }:
    {
      home.packages = [
        pkgs.neovide
        (pkgs.writeShellApplication {
          name = "nvide";
          runtimeInputs = [ pkgs.neovide ];
          text = ''
            # Without --no-startup-message-capture noice refuses to work.
            exec neovide --no-startup-message-capture --neovim-bin ${config.programs.nixvim.build.package}/bin/nvim "$@"
          '';
        })
      ];
    };
}
