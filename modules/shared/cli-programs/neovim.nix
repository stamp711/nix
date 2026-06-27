# Neovim: the nixvim config (nixvim/) as `nvim`, plus lazyvim-nix as `lvim`
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
      imports = [
        inputs.nixvim.homeModules.nixvim
        inputs.lazyvim.homeManagerModules.default
      ];

      # programs.nixvim (not the bare package) so per-host `programs.nixvim.*` overrides merge.
      # enable stays off: it asserts against programs.neovim, which lvim enables.
      programs.nixvim = {
        nixpkgs.pkgs = pkgs;
        imports = [ self.nixvimModules.default ];
      };

      home.packages = [
        # hiPrio so nixvim wins the `nvim` name over lazyvim's programs.neovim install
        (lib.hiPrio config.programs.nixvim.build.package)
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
