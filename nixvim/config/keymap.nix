{
  flake.nixvimModules.default =
    # Generic keymaps, the which-key popup, and its generic-group labels.
    {
      plugins.which-key = {
        enable = true;
        settings.preset = "helix";
      };

      # which-key groups
      extraConfigLua = ''
        require("which-key").add({
          -- proxy surfaces the <c-w> window builtins under the menu; expand live-lists windows
          { "<leader>w", group = "windows", proxy = "<c-w>", expand = function() return require("which-key.extras").expand.win() end },
          { "<leader>q", group = "quit/session" },
          { "<leader><tab>", group = "tabs" },
          { "]", group = "next" },
          { "[", group = "prev" },
          { "z", group = "fold" },
        })
      '';

      keymaps = [
        {
          key = "<Esc>";
          mode = [
            "i"
            "n"
            "s"
          ];
          action.__raw = ''
            function()
              vim.cmd("noh")
              pcall(vim.snippet.stop)
              return "<esc>"
            end'';
          options = {
            expr = true;
            desc = "Escape and Clear hlsearch";
          };
        }
        {
          key = "<C-h>";
          mode = [
            "n"
            "t" # also in terminal mode
          ];
          action = "<Cmd>wincmd h<CR>";
          options.desc = "Go to Left Window";
        }
        {
          key = "<C-j>";
          mode = [
            "n"
            "t"
          ];
          action = "<Cmd>wincmd j<CR>";
          options.desc = "Go to Lower Window";
        }
        {
          key = "<C-k>";
          mode = [
            "n"
            "t"
          ];
          action = "<Cmd>wincmd k<CR>";
          options.desc = "Go to Upper Window";
        }
        {
          key = "<C-l>";
          mode = [
            "n"
            "t"
          ];
          action = "<Cmd>wincmd l<CR>";
          options.desc = "Go to Right Window";
        }

        # j/k move by display line unless a count is given.
        {
          key = "j";
          mode = [
            "n"
            "x"
          ];
          action = "v:count == 0 ? 'gj' : 'j'";
          options = {
            expr = true;
            silent = true;
            desc = "Down";
          };
        }
        {
          key = "k";
          mode = [
            "n"
            "x"
          ];
          action = "v:count == 0 ? 'gk' : 'k'";
          options = {
            expr = true;
            silent = true;
            desc = "Up";
          };
        }
        {
          key = "<Down>";
          mode = [
            "n"
            "x"
          ];
          action = "v:count == 0 ? 'gj' : 'j'";
          options = {
            expr = true;
            silent = true;
            desc = "Down";
          };
        }
        {
          key = "<Up>";
          mode = [
            "n"
            "x"
          ];
          action = "v:count == 0 ? 'gk' : 'k'";
          options = {
            expr = true;
            silent = true;
            desc = "Up";
          };
        }

        # n/N keep the search direction and reveal the match.
        {
          key = "n";
          mode = "n";
          action = "'Nn'[v:searchforward].'zv'";
          options = {
            expr = true;
            desc = "Next Search Result";
          };
        }
        {
          key = "N";
          mode = "n";
          action = "'nN'[v:searchforward].'zv'";
          options = {
            expr = true;
            desc = "Prev Search Result";
          };
        }

        {
          key = "<A-j>";
          mode = "n";
          action = "<cmd>execute 'move .+' . v:count1<cr>==";
          options.desc = "Move Down";
        }
        {
          key = "<A-k>";
          mode = "n";
          action = "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==";
          options.desc = "Move Up";
        }
        {
          key = "<A-j>";
          mode = "v";
          action = '':<C-u>execute "'<,'>move '>+" . v:count1<cr>gv=gv'';
          options.desc = "Move Down";
        }
        {
          key = "<A-k>";
          mode = "v";
          action = '':<C-u>execute "'<,'>move '<-" . (v:count1 + 1)<cr>gv=gv'';
          options.desc = "Move Up";
        }
        {
          key = "<A-j>";
          mode = "i";
          action = "<esc><cmd>m .+1<cr>==gi";
          options.desc = "Move Down";
        }
        {
          key = "<A-k>";
          mode = "i";
          action = "<esc><cmd>m .-2<cr>==gi";
          options.desc = "Move Up";
        }

        {
          key = "<";
          mode = "x";
          action = "<gv";
          options.desc = "Indent left";
        }
        {
          key = ">";
          mode = "x";
          action = ">gv";
          options.desc = "Indent right";
        }

        # <c-g>u breaks undo so each clause is separately undoable.
        {
          key = ",";
          mode = "i";
          action = ",<c-g>u";
        }
        {
          key = ".";
          mode = "i";
          action = ".<c-g>u";
        }
        {
          key = ";";
          mode = "i";
          action = ";<c-g>u";
        }

        {
          key = "gco";
          mode = "n";
          action = "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>";
          options.desc = "Add Comment Below";
        }
        {
          key = "gcO";
          mode = "n";
          action = "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>";
          options.desc = "Add Comment Above";
        }

        {
          key = "<C-Up>";
          mode = "n";
          action = "<cmd>resize +2<cr>";
          options.desc = "Increase Window Height";
        }
        {
          key = "<C-Down>";
          mode = "n";
          action = "<cmd>resize -2<cr>";
          options.desc = "Decrease Window Height";
        }
        {
          key = "<C-Left>";
          mode = "n";
          action = "<cmd>vertical resize -2<cr>";
          options.desc = "Decrease Window Width";
        }
        {
          key = "<C-Right>";
          mode = "n";
          action = "<cmd>vertical resize +2<cr>";
          options.desc = "Increase Window Width";
        }

        {
          key = "<C-s>";
          mode = [
            "i"
            "x"
            "n"
            "s"
          ];
          action = "<cmd>w<cr><esc>";
          options.desc = "Save File";
        }
        {
          key = "<leader>K";
          mode = "n";
          action = "<cmd>norm! K<cr>";
          options.desc = "Keywordprg";
        }
        {
          key = "<leader>fn";
          mode = "n";
          action = "<cmd>enew<cr>";
          options.desc = "New File";
        }
        {
          key = "<leader>qq";
          mode = "n";
          action = "<cmd>qa<cr>";
          options.desc = "Quit All";
        }
        {
          key = "<leader>?";
          mode = "n";
          action.__raw = "function() require('which-key').show({ global = false }) end";
          options.desc = "Buffer Keymaps (which-key)";
        }

        {
          key = "<leader>wd";
          mode = "n";
          action = "<C-w>c";
          options.desc = "Delete Window";
        }
        {
          key = "<leader>-";
          mode = "n";
          action = "<C-w>s";
          options.desc = "Split Window Below";
        }
        {
          key = "<leader>|";
          mode = "n";
          action = "<C-w>v";
          options.desc = "Split Window Right";
        }
        {
          # loop keeps the <c-w> menu open to chain window ops (split, move, resize) until <esc>
          key = "<C-w><Space>";
          mode = "n";
          action.__raw = ''function() require("which-key").show({ keys = "<c-w>", loop = true }) end'';
          options.desc = "Window Hydra Mode (which-key)";
        }

        {
          key = "<leader><tab><tab>";
          mode = "n";
          action = "<cmd>tabnew<cr>";
          options.desc = "New Tab";
        }
        {
          key = "<leader><tab>]";
          mode = "n";
          action = "<cmd>tabnext<cr>";
          options.desc = "Next Tab";
        }
        {
          key = "<leader><tab>[";
          mode = "n";
          action = "<cmd>tabprevious<cr>";
          options.desc = "Previous Tab";
        }
        {
          key = "<leader><tab>d";
          mode = "n";
          action = "<cmd>tabclose<cr>";
          options.desc = "Close Tab";
        }
        {
          key = "<leader><tab>o";
          mode = "n";
          action = "<cmd>tabonly<cr>";
          options.desc = "Close Other Tabs";
        }
        {
          key = "<leader><tab>l";
          mode = "n";
          action = "<cmd>tablast<cr>";
          options.desc = "Last Tab";
        }
        {
          key = "<leader><tab>f";
          mode = "n";
          action = "<cmd>tabfirst<cr>";
          options.desc = "First Tab";
        }
        {
          key = "<C-`>";
          mode = [
            "n"
            "t"
          ];
          action.__raw = "function() Snacks.terminal() end";
          options.desc = "Terminal (Root Dir)";
        }
      ];
    };
}
