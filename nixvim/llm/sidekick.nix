{
  flake.nixvimModules.default = { lib, ... }: {

    plugins.sidekick.enable = true;
    lsp.servers.copilot.enable = true; # sidekick NES (next-edit suggestions) runs off the Copilot LSP

    # NES/CLI status -> lualine_x, order 20 (scheme in ui/lualine.nix)
    plugins.lualine.settings.sections.lualine_x = lib.mkOrder 20 [
      # CLI count
      {
        __raw = ''
          {
            function() local s = require("sidekick.status").cli() return " " .. (#s > 1 and #s or "") end,
            cond = function() return #require("sidekick.status").cli() > 0 end,
            color = function() return { fg = Snacks.util.color("Special") } end,
          }
        '';
      }
      # NES status
      {
        __raw = ''
          (function()
            local icons = {
              Error = { "\u{f4b9}", "DiagnosticError" },
              Inactive = { "\u{f4b9}", "MsgArea" },
              Warning = { "\u{f4ba}", "DiagnosticWarn" },
              Normal = { "\u{f4b8}", "Special" },
            }
            return {
              function()
                local s = require("sidekick.status").get()
                return s and vim.tbl_get(icons, s.kind, 1)
              end,
              cond = function() return require("sidekick.status").get() ~= nil end,
              color = function()
                local s = require("sidekick.status").get()
                local hl = s and (s.busy and "DiagnosticWarn" or vim.tbl_get(icons, s.kind, 2))
                return { fg = Snacks.util.color(hl) }
              end,
            }
          end)()
        '';
      }
    ];

    # sidekick.nvim under <leader>as (CLI) + bare keys (NES)
    extraConfigLua = ''
      require("which-key").add({
        { "<leader>as", group = "sidekick", mode = { "n", "x" } },
      })
    '';

    # Snacks.toggle in Post so the Snacks global (from snacks's setup) exists
    extraConfigLuaPost = ''
      Snacks.toggle({
        name = "Sidekick NES",
        get = function() return require("sidekick.nes").enabled end,
        set = function(state) require("sidekick.nes").enable(state) end,
      }):map("<leader>uN")
    '';

    keymaps = [
      # sidekick CLI under <leader>as (LazyVim's sidekick.lua letters as the 3rd char)
      {
        mode = "n";
        key = "<leader>asa";
        action.__raw = ''function() require("sidekick.cli").toggle() end'';
        options.desc = "Toggle CLI";
      }
      {
        mode = "n";
        key = "<leader>ass";
        action.__raw = ''function() require("sidekick.cli").select() end'';
        options.desc = "Select CLI";
      }
      {
        mode = "n";
        key = "<leader>asd";
        action.__raw = ''function() require("sidekick.cli").close() end'';
        options.desc = "Detach Session";
      }
      {
        mode = [
          "n"
          "x"
        ];
        key = "<leader>ast";
        action.__raw = ''function() require("sidekick.cli").send({ msg = "{this}" }) end'';
        options.desc = "Send This";
      }
      {
        mode = "n";
        key = "<leader>asf";
        action.__raw = ''function() require("sidekick.cli").send({ msg = "{file}" }) end'';
        options.desc = "Send File";
      }
      {
        mode = "x";
        key = "<leader>asv";
        action.__raw = ''function() require("sidekick.cli").send({ msg = "{selection}" }) end'';
        options.desc = "Send Selection";
      }
      {
        mode = [
          "n"
          "x"
        ];
        key = "<leader>asp";
        action.__raw = ''function() require("sidekick.cli").prompt() end'';
        options.desc = "Select Prompt";
      }

      # sidekick NES (match LazyVim keys)
      {
        mode = "n";
        key = "<tab>";
        action.__raw = ''function() if not require("sidekick").nes_jump_or_apply() then return "<Tab>" end end'';
        options = {
          expr = true;
          desc = "Goto/Apply Next Edit Suggestion";
        };
      }
      {
        mode = [
          "n"
          "t"
          "i"
          "x"
        ];
        key = "<c-.>";
        action.__raw = ''function() require("sidekick.cli").focus() end'';
        options.desc = "Sidekick Focus";
      }
    ];

  };
}
