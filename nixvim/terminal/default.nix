# Zed-like terminal pane on Snacks: one visible split, a global list of terminals
# to tab between. Positional tab numbers, Snacks coloring + bindings kept.
# Manager logic lives in ./manager.lua.
{
  flake.nixvimModules.default = {
    extraConfigLua = ''
      do
        -- winbar tabs + manager keys, scoped to manager terminals
        local manager_win = {
          wo = { winbar = "%!v:lua.Terminals.winbar()" },
          keys = {
            term_toggle = { "<C-`>", function() Terminals.toggle() end, desc = "Toggle Terminal Pane", mode = "t" },
            term_new    = { "<C-S-`>", function() Terminals.new() end, desc = "New Terminal", mode = "t" },
            -- neovide sends <C-~> for Ctrl+Shift+backtick
            term_newalt = { "<C-~>", function() Terminals.new() end, desc = "New Terminal", mode = "t" },
            -- Zed-style tab cycle: [ = prev, ] = next; Ctrl and Cmd both bound
            term_next   = { "<C-S-]>", function() Terminals.cycle(1) end, desc = "Next Terminal", mode = "t" },
            term_prev   = { "<C-S-[>", function() Terminals.cycle(-1) end, desc = "Previous Terminal", mode = "t" },
            term_next_d = { "<D-S-]>", function() Terminals.cycle(1) end, desc = "Next Terminal", mode = "t" },
            term_prev_d = { "<D-S-[>", function() Terminals.cycle(-1) end, desc = "Previous Terminal", mode = "t" },
            term_zoom   = { "<C-Esc>", function() Terminals.zoom() end, desc = "Zoom Terminal", mode = "t" },
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
      # Zed-style tab cycle: [ = prev, ] = next; Ctrl and Cmd both bound
      {
        key = "<C-S-]>";
        mode = "n";
        action.__raw = "function() Terminals.cycle(1) end";
        options.desc = "Next Terminal";
      }
      {
        key = "<D-S-]>";
        mode = "n";
        action.__raw = "function() Terminals.cycle(1) end";
        options.desc = "Next Terminal";
      }
      {
        key = "<C-S-[>";
        mode = "n";
        action.__raw = "function() Terminals.cycle(-1) end";
        options.desc = "Previous Terminal";
      }
      {
        key = "<D-S-[>";
        mode = "n";
        action.__raw = "function() Terminals.cycle(-1) end";
        options.desc = "Previous Terminal";
      }
    ];

    # Global (every Snacks terminal): <C-hjkl> window-nav, handled by Terminals.nav
    # in manager.lua. Winbar tabs + manager keys are per-terminal (manager_win), so
    # only manager terminals get them.
    plugins.snacks.settings.terminal.win.keys.__raw = ''
      {
        nav_h = { "<C-h>", function(self) return Terminals.nav(self, "h") end, desc = "Go to Left Window", expr = true, mode = "t" },
        nav_j = { "<C-j>", function(self) return Terminals.nav(self, "j") end, desc = "Go to Lower Window", expr = true, mode = "t" },
        nav_k = { "<C-k>", function(self) return Terminals.nav(self, "k") end, desc = "Go to Upper Window", expr = true, mode = "t" },
        nav_l = { "<C-l>", function(self) return Terminals.nav(self, "l") end, desc = "Go to Right Window", expr = true, mode = "t" },
      }
    '';
  };
}
