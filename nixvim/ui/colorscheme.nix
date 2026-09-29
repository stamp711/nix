{
  flake.nixvimModules.default =
    {
      config,
      lib, # for lib.nixvim
      pkgs,
      ...
    }:
    {

      # We pick the active colorscheme ourselves (below), so suppress nixvim's auto-apply.
      colorscheme = lib.mkForce null;

      extraPlugins = [
        pkgs.vimPlugins.auto-dark-mode-nvim
        pkgs.vimPlugins.night-owl-nvim
      ];

      colorschemes.kanagawa = {
        enable = true;
        settings = {
          theme = "wave";
          commentStyle.italic = false;
          keywordStyle.italic = false;
        };
      };

      # dark
      colorschemes.base16 = {
        enable = true;
        setUpBar = false; # Keep lualine's automatic theme switching.
        # Load through the named colorscheme below, after choosing light/dark mode.
        luaConfig.content = lib.mkForce "";
        # Tomorrow Night Blue
        # Palette source:
        #   https://github.com/chriskempson/vim-tomorrow-theme/blob/fd25d3be7558b9f9533837f25d7b31d31438287b/colors/Tomorrow-Night-Blue.vim#L7-L18
        # Base16 role guidelines:
        #   https://github.com/tinted-theming/home/blob/main/styling.md#specific-colors-and-their-usages
        # Custom Base16 assignments:
        #   base04      <- blue
        #   base06/07   <- white foreground
        #   base0F      <- orange
        colorscheme = {
          base00 = "#002451";
          base01 = "#00346e";
          base02 = "#003f8e";
          base03 = "#7285b7";
          base04 = "#bbdaff"; # secondary text: line numbers, inactive bars
          base05 = "#ffffff";
          base06 = "#ffffff"; # bright foreground: Diffview titles and filenames
          base07 = "#ffffff"; # brightest foreground; terminal bright white
          base08 = "#ff9da4";
          base09 = "#ffc58f";
          base0A = "#ffeead";
          base0B = "#d1f1a9";
          base0C = "#99ffff";
          base0D = "#bbdaff";
          base0E = "#ebbbff";
          base0F = "#ffc58f"; # delimiters and special characters
        };
      };

      # our own base16-tomorrow-night-blue
      extraFiles."colors/base16-tomorrow-night-blue.lua".text = ''
        vim.cmd("highlight clear")
        vim.g.colors_name = "base16-tomorrow-night-blue"
        require("base16-colorscheme").setup(
          ${lib.nixvim.toLuaObject config.colorschemes.base16.colorscheme},
          ${lib.nixvim.toLuaObject config.colorschemes.base16.settings}
        )
      '';

      # customized night-owl; the different name avoids runtime-path collision.
      extraFiles."colors/night-owl-custom.lua".text = ''
        require("night-owl").setup({ italics = false })
        dofile("${pkgs.vimPlugins.night-owl-nvim}/colors/night-owl.lua")
        vim.g.colors_name = "night-owl-custom"

        -- Muted diff backgrounds; preserve syntax foregrounds.
        local c = require("night-owl.palette")
        local blend = require("snacks.util").blend
        for group, bg in pairs({
          DiffAdd = blend(c.sign_add, c.bg, 0.08),
          DiffDelete = blend(c.sign_delete, c.bg, 0.08),
          DiffChange = blend(c.sign_change, c.bg, 0.08),
          DiffText = blend(c.sign_change, c.bg, 0.15),
        }) do
          vim.api.nvim_set_hl(0, group, { bg = bg })
        end
      '';

      # light
      colorschemes.modus = {
        enable = true;
        settings = {
          variants.modus_operandi = "tinted";
          styles = {
            comments.italic = false;
            keywords.italic = false;
          };
          # Match Zed "Modus Operandi Tinted" overrides (warm-neutral tuning).
          on_colors.__raw = ''
            function(c)
              c.comment = "#8a8178" -- comment + code-lens + inlay hint (Zed: comment, hint)
            end
          '';
          on_highlights.__raw = ''
            function(hl, c)
              hl.CursorLine.bg = "#efeae3" -- Zed: editor.active_line.background (text area only)
              -- keep the gutter coherent: current-line bg matches the rest of the gutter
              hl.CursorLineNr.bg = hl.LineNr.bg
              hl.LspInlayHint.italic = false
              hl.Cursor.bg = "#5a544c" -- Zed: players.cursor
              hl.Visual = { bg = "#c2bcb5" } -- Zed: players[0].background; bg-only so syntax colors show through the selection
              hl.SnacksIndent = { fg = c.bg_dim } -- indent guides at modus's own quiet bg_dim, not the loud NonText
              -- Trouble sidebar on editor Normal, not modus's dark float bg (bg_active); indent sub-groups follow TroubleIndent.
              for _, g in ipairs({ "TroubleNormal", "TroubleNormalNC", "TroubleIndent" }) do
                hl[g] = { link = "Normal" }
              end
            end
          '';
        };
      };

      extraConfigLua = ''
        require("auto-dark-mode").setup() -- defaults to set `background` to dark/light from the OS
        vim.cmd.colorscheme(vim.o.background == "light" and "modus_operandi" or "night-owl-custom")
      '';

      # When background is changed, apply the theme.
      autoGroups.theme.clear = true;
      autoCmd = [
        {
          event = "OptionSet";
          pattern = "background";
          group = "theme";
          callback.__raw = ''
            function()
              if vim.v.option_old ~= vim.v.option_new then
                -- defer the colorscheme switch until after nvim's internal background handling
                vim.schedule(function()
                  vim.cmd.colorscheme(vim.o.background == "light" and "modus_operandi" or "night-owl-custom")
                end)
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
