{
  description = "Neovim with LazyVim configuration";

  module =
    { pkgs, ... }:
    {
      programs.neovim = {
        enable = true;
        defaultEditor = true;

        # Tools LazyVim needs
        extraPackages = with pkgs; [
          ripgrep
          fd
        ];
      };

      # Copy LazyVim config
      xdg.configFile = {
        "nvim/init.lua".source = ./nvim/init.lua;
        "nvim/lua".source = ./nvim/lua;
        "nvim/lazyvim.json".source = ./nvim/lazyvim.json;
      };
    };
}
