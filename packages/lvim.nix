# lazyvim-nix's neovim in its own eval: lazyvim needs programs.neovim, which the host's
# programs.nixvim.enable forbids.
{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      lazyvim =
        (inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            inputs.lazyvim.homeManagerModules.default
            {
              home = {
                username = "lvim";
                homeDirectory = "/build";
                stateVersion = "26.11";
              };
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
            }
          ];
        }).config.programs.neovim.finalPackage;
    in
    {
      packages.lvim = pkgs.runCommand "lvim" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
        makeWrapper ${lazyvim}/bin/nvim $out/bin/lvim --set NVIM_APPNAME lazyvim
      '';
    };
}
