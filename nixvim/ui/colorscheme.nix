{
  flake.nixvimModules.default = { pkgs, lib, ... }: {

    # We pick the active colorscheme ourselves (below), so suppress nixvim's auto-apply.
    colorscheme = lib.mkForce null;

    colorschemes.gruvbox = {
      enable = true;
      settings.italic = {
        strings = false;
        comments = false;
        operators = false;
        folds = false;
        emphasis = false;
      };
    };

    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "latte";
    };

    extraPlugins = [ pkgs.vimPlugins.auto-dark-mode-nvim ];

    extraConfigLua = ''
      require("auto-dark-mode").setup() -- defaults to set `background` to dark/light from the OS
      vim.cmd.colorscheme(vim.o.background == "light" and "catppuccin" or "gruvbox")
    '';

    # When background is changed, apply the theme.
    autoCmd = [
      {
        event = "OptionSet";
        pattern = "background";
        callback.__raw = ''
          function()
            if vim.v.option_old ~= vim.v.option_new then
              vim.cmd.colorscheme(vim.o.background == "light" and "catppuccin" or "gruvbox")
            end
          end
        '';
      }
    ];

    keymaps = [
      {
        key = "<leader>uC";
        mode = "n";
        action.__raw = "function() Snacks.picker.colorschemes() end";
        options.desc = "Colorschemes";
      }
    ];

    extraConfigLuaPost = ''
      Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
    '';

  };
}
