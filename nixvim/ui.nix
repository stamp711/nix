{
  flake.nixvimModules.default =
    # Appearance, panels, and UI toggles.
    {
      # which-key groups
      extraConfigLua = ''
        require("which-key").add({
          { "<leader>u", group = "ui" },
          -- expand: live-list the open buffers in the <leader>b menu
          { "<leader>b", group = "buffer", expand = function() return require("which-key.extras").expand.buf() end },
          { "<leader>sn", group = "noice" },
        })
      '';

      # snacks toggles via :map, in Post so the Snacks global (set by snacks's own setup) already exists
      extraConfigLuaPost = ''
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2, name = "Conceal Level" }):map("<leader>uc")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        Snacks.toggle.indent():map("<leader>ug")
        Snacks.toggle.zen():map("<leader>uz")
        Snacks.toggle({
          name = "Auto Format (Global)",
          get = function() return not vim.g.disable_autoformat end,
          set = function(state) vim.g.disable_autoformat = not state end,
        }):map("<leader>uf")
        Snacks.toggle({
          name = "Auto Format (Buffer)",
          get = function() return not (vim.g.disable_autoformat or vim.b.disable_autoformat) end,
          set = function(state) vim.b.disable_autoformat = not state end,
        }):map("<leader>uF")
        Snacks.toggle({
          name = "Git Signs",
          get = function() return require("gitsigns.config").config.signcolumn end,
          set = function(state) require("gitsigns").toggle_signs(state) end,
        }):map("<leader>uG")
        Snacks.toggle({
          name = "Mini Pairs",
          get = function() return not vim.g.minipairs_disable end,
          set = function(state) vim.g.minipairs_disable = not state end,
        }):map("<leader>up")
        Snacks.toggle.option("showtabline", { off = 0, on = vim.o.showtabline > 0 and vim.o.showtabline or 2, name = "Tabline" }):map("<leader>uA")
        Snacks.toggle.zoom():map("<leader>wm"):map("<leader>uZ")
      '';

      colorschemes.onedark = {
        enable = true;
        settings.style = "warm";
      };

      plugins.lualine.enable = true;

      plugins.mini-icons.enable = true;

      plugins.noice = {
        enable = true;
        settings = {
          lsp.override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = true;
            "vim.lsp.util.stylize_markdown" = true;
            "cmp.entry.get_documentation" = true;
          };
          presets = {
            bottom_search = true;
            command_palette = true;
            long_message_to_split = true;
          };
          routes = [
            {
              # route write/undo/redo notifications to the corner mini view
              filter = {
                event = "msg_show";
                any = [
                  { find = "%d+L, %d+B"; }
                  { find = "; after #%d+"; }
                  { find = "; before #%d+"; }
                ];
              };
              view = "mini";
            }
          ];
        };
      };

      plugins.bufferline = {
        enable = true;
        settings.options = {
          always_show_bufferline = false;
          diagnostics = "nvim_lsp";
          close_command.__raw = "function(n) Snacks.bufdelete(n) end";
          right_mouse_command.__raw = "function(n) Snacks.bufdelete(n) end";
          diagnostics_indicator.__raw = ''
            function(_, _, diag)
              local icons = { Error = " ", Warn = " " }
              local ret = (diag.error and icons.Error .. diag.error .. " " or "")
                .. (diag.warning and icons.Warn .. diag.warning or "")
              return vim.trim(ret)
            end'';
          # reserve a column for the snacks explorer/picker sidebar so tabs don't span it
          offsets = [
            { filetype = "snacks_layout_box"; }
          ];
        };
      };

      plugins.snacks = {
        enable = true;
        settings = {
          bigfile.enabled = true; # disable expensive features on very large files
          quickfile.enabled = true; # render the file before plugins finish loading
          explorer.enabled = true;
          dashboard = {
            enabled = true;
            # snacks' default "startup" section calls require("lazy.stats"); no lazy.nvim here, so drop it
            sections = [
              { section = "header"; }
              {
                section = "keys";
                gap = 1;
                padding = 1;
              }
            ];
          };
          indent.enabled = true;
          scope.enabled = true;
          words.enabled = true;
          notifier.enabled = true;
          input.enabled = true;
        };
      };

      keymaps =
        let
          lua = key: desc: body: {
            inherit key;
            mode = "n";
            action.__raw = "function() ${body} end";
            options.desc = desc;
          };
          cmd = key: desc: command: {
            inherit key;
            mode = "n";
            action = command;
            options = {
              silent = true;
              inherit desc;
            };
          };
        in
        [
          (lua "<leader>e" "Explorer Snacks (root dir)" "Snacks.explorer({ cwd = Root() })")
          (lua "<leader>E" "Explorer Snacks (cwd)" "Snacks.explorer({ cwd = vim.fn.getcwd() })")
          (lua "<leader>fe" "Explorer Snacks (root dir)" "Snacks.explorer({ cwd = Root() })")
          (lua "<leader>fE" "Explorer Snacks (cwd)" "Snacks.explorer({ cwd = vim.fn.getcwd() })")
          (lua "<leader>n" "Notification History" "Snacks.picker.notifications()")

          (cmd "H" "Prev Buffer" "<cmd>BufferLineCyclePrev<cr>")
          (cmd "L" "Next Buffer" "<cmd>BufferLineCycleNext<cr>")
          (cmd "[b" "Prev Buffer" "<cmd>BufferLineCyclePrev<cr>")
          (cmd "]b" "Next Buffer" "<cmd>BufferLineCycleNext<cr>")
          (cmd "[B" "Move buffer prev" "<cmd>BufferLineMovePrev<cr>")
          (cmd "]B" "Move buffer next" "<cmd>BufferLineMoveNext<cr>")
          (lua "<leader>bd" "Delete Buffer" "Snacks.bufdelete()")
          (lua "<leader>bo" "Delete Other Buffers" "Snacks.bufdelete.other()")
          (lua "<leader>bi" "Delete Invisible Buffers" "Snacks.bufdelete.invisible()")
          (cmd "<leader>bb" "Switch to Other Buffer" "<cmd>e #<cr>")
          (cmd "<leader>`" "Switch to Other Buffer" "<cmd>e #<cr>")
          (cmd "<leader>bD" "Delete Buffer and Window" "<cmd>bd<cr>")
          (cmd "<leader>bp" "Toggle Pin" "<cmd>BufferLineTogglePin<cr>")
          (cmd "<leader>bP" "Delete Non-Pinned Buffers" "<cmd>BufferLineGroupClose ungrouped<cr>")
          (cmd "<leader>br" "Delete Buffers to the Right" "<cmd>BufferLineCloseRight<cr>")
          (cmd "<leader>bl" "Delete Buffers to the Left" "<cmd>BufferLineCloseLeft<cr>")
          (cmd "<leader>bj" "Pick Buffer" "<cmd>BufferLinePick<cr>")

          (lua "<leader>un" "Dismiss All Notifications" "Snacks.notifier.hide()")
          (lua "<leader>uC" "Colorschemes" "Snacks.picker.colorschemes()")
          (lua "<leader>ui" "Inspect Pos" "vim.show_pos()")
          (lua "<leader>uI" "Inspect Tree" "vim.treesitter.inspect_tree()")
          (cmd "<leader>ur" "Redraw / Clear hlsearch / Diff Update"
            "<cmd>nohlsearch<bar>diffupdate<bar>normal! <C-L><cr>"
          )

          # noice
          (lua "<leader>snl" "Noice Last Message" ''require("noice").cmd("last")'')
          (lua "<leader>snh" "Noice History" ''require("noice").cmd("history")'')
          (lua "<leader>sna" "Noice All" ''require("noice").cmd("all")'')
          (lua "<leader>snd" "Dismiss All" ''require("noice").cmd("dismiss")'')
          {
            key = "<S-Enter>";
            mode = "c";
            action.__raw = ''function() require("noice").redirect(vim.fn.getcmdline()) end'';
            options.desc = "Redirect Cmdline";
          }
          {
            key = "<C-f>";
            mode = [
              "i"
              "n"
              "s"
            ];
            action.__raw = ''function() if not require("noice.lsp").scroll(4) then return "<C-f>" end end'';
            options = {
              silent = true;
              expr = true;
              desc = "Scroll Forward";
            };
          }
          {
            key = "<C-b>";
            mode = [
              "i"
              "n"
              "s"
            ];
            action.__raw = ''function() if not require("noice.lsp").scroll(-4) then return "<C-b>" end end'';
            options = {
              silent = true;
              expr = true;
              desc = "Scroll Backward";
            };
          }
        ];
    }

  ;
}
