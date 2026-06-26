# Neovide GUI wrappers: `nvide` drives the nvf nvim, `lvide` drives the
# lazyvim-nix neovim (NVIM_APPNAME=lazyvim, config in ~/.config/lazyvim).
{ self, ... }:
{
  flake.homeModules.desktop-programs = { config, pkgs, ... }: {
    home.packages = [
      pkgs.neovide
      (pkgs.writeShellApplication {
        name = "nvide";
        runtimeInputs = [ pkgs.neovide ];
        text = ''
          exec neovide --neovim-bin ${self.packages.${pkgs.stdenv.hostPlatform.system}.nvim}/bin/nvim "$@"
        '';
      })
      (pkgs.writeShellApplication {
        name = "lvide";
        runtimeInputs = [ pkgs.neovide ];
        text = ''
          export NVIM_APPNAME=lazyvim
          exec neovide --neovim-bin ${config.programs.neovim.finalPackage}/bin/nvim "$@"
        '';
      })
    ];
  };
}
