{
  flake.nixvimModules.default =
    { lib, pkgs, ... }:
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

      colorschemes.base16 = {
        enable = true;
        setUpBar = false; # Keep lualine's automatic theme switching.
        colorscheme = "phd";
        luaConfig.content = lib.mkForce "";
      };

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
        vim.cmd.colorscheme(vim.o.background == "light" and "modus_operandi" or "base16-phd")
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
                  vim.cmd.colorscheme(vim.o.background == "light" and "modus_operandi" or "base16-phd")
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
