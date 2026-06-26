# Neovim: the nvf build (packages/nvim) as `nvim`, plus lazyvim-nix as `lvim`
#  LazyVim lives in ~/.config/lazyvim via NVIM_APPNAME.
{ self, inputs, ... }: {
  flake.homeModules.cli-programs =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [ inputs.lazyvim.homeManagerModules.default ];

      home.packages = [
        # hiPrio so nvf wins the `nvim` name over lazyvim's programs.neovim install
        (lib.hiPrio self.packages.${pkgs.stdenv.hostPlatform.system}.nvim)
        (pkgs.runCommand "lvim" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
          makeWrapper ${config.programs.neovim.finalPackage}/bin/nvim $out/bin/lvim \
            --set NVIM_APPNAME lazyvim
        '')
      ];
      home.sessionVariables.EDITOR = "nvim";

      programs.lazyvim = {
        enable = true;
        appName = "lazyvim";
        installCoreDependencies = true;
        extras = {
          lang.clangd.enable = true;
          lang.json.enable = true;
          lang.markdown.enable = true;
          lang.nix.enable = true;
          lang.python.enable = true;
          lang.rust.enable = true;
          lang.toml.enable = true;
          lang.zig.enable = true;
        };
        plugins.colorscheme = ''
          return {
            { "navarasu/onedark.nvim", priority = 1000, opts = { style = "warm" } },
            { "LazyVim/LazyVim", opts = { colorscheme = "onedark" } },
          }
        '';
      };
    };
}
