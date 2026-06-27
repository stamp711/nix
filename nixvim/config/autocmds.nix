{
  flake.nixvimModules.default =
    # Autocmds: event-driven editor behaviors, ported from lazyvim config/autocmds.lua.
    {
      autoGroups = {
        checktime.clear = true;
        highlight_yank.clear = true;
        last_loc.clear = true;
        resize_splits.clear = true;
        close_with_q.clear = true;
        man_unlisted.clear = true;
        wrap_spell.clear = true;
        json_conceal.clear = true;
        auto_create_dir.clear = true;
      };

      autoCmd = [
        {
          event = [
            "FocusGained"
            "TermClose"
            "TermLeave"
          ];
          group = "checktime";
          desc = "Reload buffer if the file changed externally";
          callback.__raw = ''
            function()
              if vim.o.buftype ~= "nofile" then
                vim.cmd("checktime")
              end
            end
          '';
        }
        {
          event = "TextYankPost";
          group = "highlight_yank";
          desc = "Highlight on yank";
          callback.__raw = ''
            function()
              if vim.fn.has("nvim-0.13") == 1 then
                vim.hl.hl_op()
              else
                (vim.hl or vim.highlight).on_yank()
              end
            end
          '';
        }
        {
          event = "BufReadPost";
          group = "last_loc";
          desc = "Restore cursor to last position";
          callback.__raw = ''
            function(event)
              local exclude = { "gitcommit" }
              local buf = event.buf
              if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].last_loc then
                return
              end
              vim.b[buf].last_loc = true
              local mark = vim.api.nvim_buf_get_mark(buf, '"')
              local lcount = vim.api.nvim_buf_line_count(buf)
              if mark[1] > 0 and mark[1] <= lcount then
                pcall(vim.api.nvim_win_set_cursor, 0, mark)
              end
            end
          '';
        }
        {
          event = "VimResized";
          group = "resize_splits";
          desc = "Equalize splits on resize";
          callback.__raw = ''
            function()
              local current_tab = vim.fn.tabpagenr()
              vim.cmd("tabdo wincmd =")
              vim.cmd("tabnext " .. current_tab)
            end
          '';
        }
        {
          event = "FileType";
          pattern = [
            "checkhealth"
            "gitsigns-blame"
            "grug-far"
            "help"
            "lspinfo"
            "qf"
          ];
          group = "close_with_q";
          desc = "Close utility buffers with q";
          callback.__raw = ''
            function(event)
              vim.bo[event.buf].buflisted = false
              vim.schedule(function()
                vim.keymap.set("n", "q", function()
                  vim.cmd("close")
                  pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
                end, { buffer = event.buf, silent = true, desc = "Quit buffer" })
              end)
            end
          '';
        }
        {
          event = "FileType";
          pattern = "man";
          group = "man_unlisted";
          desc = "Make man buffers unlisted";
          callback.__raw = ''
            function(event)
              vim.bo[event.buf].buflisted = false
            end
          '';
        }
        {
          event = "FileType";
          pattern = [
            "text"
            "plaintex"
            "typst"
            "gitcommit"
            "markdown"
          ];
          group = "wrap_spell";
          desc = "Enable wrap and spell in prose";
          callback.__raw = ''
            function()
              vim.opt_local.wrap = true
              vim.opt_local.spell = true
            end
          '';
        }
        {
          event = "FileType";
          pattern = [
            "json"
            "jsonc"
            "json5"
          ];
          group = "json_conceal";
          desc = "Disable conceal in json";
          callback.__raw = ''
            function()
              vim.opt_local.conceallevel = 0
            end
          '';
        }
        {
          event = "BufWritePre";
          group = "auto_create_dir";
          desc = "Auto-create parent dirs on save";
          callback.__raw = ''
            function(event)
              if event.match:match("^%w%w+:[\\/][\\/]") then
                return
              end
              local file = vim.uv.fs_realpath(event.match) or event.match
              vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
            end
          '';
        }
      ];
    };
}
