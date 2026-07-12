{
  flake.nixvimModules.default = {

    keymaps = [
      {
        key = "<leader>ft";
        mode = "n";
        action.__raw = "function() Snacks.terminal(nil, { cwd = Root() }) end";
        options.desc = "Terminal (Root Dir)";
      }
      {
        key = "<leader>fT";
        mode = "n";
        action.__raw = "function() Snacks.terminal() end";
        options.desc = "Terminal (cwd)";
      }
      {
        key = "<C-`>";
        mode = [
          "n"
          "t"
        ];
        action.__raw = "function() Snacks.terminal.focus(nil, { cwd = Root() }) end";
        options.desc = "Terminal (Root Dir)";
      }
    ];

    # terminal-mode window keys from LazyVim: <C-`> hides in place (avoids a 2nd terminal), <C-hjkl> nav
    plugins.snacks.settings.terminal.win.keys.__raw = ''
      (function()
        -- lazyvim util.lua term_nav, extended to pass the key through at a window edge
        local function term_nav(dir)
          return function(self)
            if self:is_floating() or vim.fn.winnr(dir) == vim.fn.winnr() then
              return "<c-" .. dir .. ">"
            else
              vim.schedule(function() vim.cmd.wincmd(dir) end)
            end
          end
        end
        return {
          term_hide = { "<C-`>", "hide", desc = "Hide Terminal", mode = "t" },
          nav_h = { "<C-h>", term_nav("h"), desc = "Go to Left Window", expr = true, mode = "t" },
          nav_j = { "<C-j>", term_nav("j"), desc = "Go to Lower Window", expr = true, mode = "t" },
          nav_k = { "<C-k>", term_nav("k"), desc = "Go to Upper Window", expr = true, mode = "t" },
          nav_l = { "<C-l>", term_nav("l"), desc = "Go to Right Window", expr = true, mode = "t" },
        }
      end)()
    '';

  };
}
