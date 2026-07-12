# Zed-like terminal pane on Snacks: one visible split, a global list of terminals
# to tab between. Positional tab numbers, Snacks coloring + bindings kept.
# Manager logic lives in ./manager.lua.
{
  flake.nixvimModules.default = {
    extraConfigLua = ''
      do
        -- winbar tabs + manager keys, scoped to manager terminals only so other
        -- Snacks terminals (Claude Code, popups) don't inherit them
        local manager_win = {
          wo = { winbar = "%!v:lua.Terminals.winbar()" },
          keys = {
            term_toggle = { "<C-`>", function() Terminals.toggle() end, desc = "Toggle Terminal Pane", mode = "t" },
            term_new    = { "<C-S-`>", function() Terminals.new() end, desc = "New Terminal", mode = "t" },
            -- neovide sends <C-~> for Ctrl+Shift+backtick
            term_newalt = { "<C-~>", function() Terminals.new() end, desc = "New Terminal", mode = "t" },
            term_next   = { "<C-Tab>", function() Terminals.cycle(1) end, desc = "Next Terminal", mode = "t" },
            term_prev   = { "<C-S-Tab>", function() Terminals.cycle(-1) end, desc = "Previous Terminal", mode = "t" },
          },
        }
        ${builtins.readFile ./manager.lua}
      end
    '';

    keymaps = [
      {
        key = "<C-`>";
        mode = "n";
        action.__raw = "function() Terminals.toggle() end";
        options.desc = "Toggle Terminal Pane";
      }
      {
        key = "<C-S-`>";
        mode = "n";
        action.__raw = "function() Terminals.new() end";
        options.desc = "New Terminal";
      }
      {
        # neovide folds Shift+` into ~, so Ctrl+Shift+backtick arrives as <C-~>
        key = "<C-~>";
        mode = "n";
        action.__raw = "function() Terminals.new() end";
        options.desc = "New Terminal";
      }
      {
        key = "<C-Tab>";
        mode = "n";
        action.__raw = "function() Terminals.cycle(1) end";
        options.desc = "Next Terminal";
      }
      {
        key = "<C-S-Tab>";
        mode = "n";
        action.__raw = "function() Terminals.cycle(-1) end";
        options.desc = "Previous Terminal";
      }
    ];

    # Global (every Snacks terminal): window-nav out of a terminal. Winbar tabs +
    # manager keys are set per-terminal in manager.lua, so only manager terminals get them.
    plugins.snacks.settings.terminal.win.keys.__raw = ''
      (function()
        -- lazyvim util.lua term_nav, extended to pass the key through at a window edge
        local function term_nav(dir)
          return function(self)
            if self:is_floating() or vim.fn.winnr(dir) == vim.fn.winnr() then
              return "<c-" .. dir .. ">"
            else
              vim.schedule(function()
                vim.cmd.wincmd(dir)
              end)
            end
          end
        end
        return {
          nav_h = { "<C-h>", term_nav("h"), desc = "Go to Left Window", expr = true, mode = "t" },
          nav_j = { "<C-j>", term_nav("j"), desc = "Go to Lower Window", expr = true, mode = "t" },
          nav_k = { "<C-k>", term_nav("k"), desc = "Go to Upper Window", expr = true, mode = "t" },
          nav_l = { "<C-l>", term_nav("l"), desc = "Go to Right Window", expr = true, mode = "t" },
        }
      end)()
    '';
  };
}
