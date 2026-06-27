# Neovim: hand-rolled nixvim as `nvim`; stock neovim + LazyVim starter as `lvim`.
{ self, inputs, ... }:
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      imports = [ inputs.nixvim.homeModules.nixvim ];

      programs.nixvim = {
        enable = true;
        defaultEditor = true;
        nixpkgs.pkgs = pkgs; # our overlaid, allowUnfree pkgs
        imports = [ self.nixvimModules.default ];
      };

      # lvim: stock neovim + the LazyVim starter, isolated from nvim via NVIM_APPNAME
      home.packages = [
        (pkgs.writeShellApplication {
          name = "lvim";
          runtimeInputs = [
            pkgs.neovim
            pkgs.git
          ];
          text = ''
            export NVIM_APPNAME=lazyvim
            config="''${XDG_CONFIG_HOME:-$HOME/.config}/lazyvim"
            # fetch the starter on first run
            if [ ! -e "$config/init.lua" ]; then
              git clone https://github.com/LazyVim/starter "$config"
              rm -rf "$config/.git"
            fi
            exec nvim "$@"
          '';
        })
      ];
    };
}
