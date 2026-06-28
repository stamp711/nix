{
  flake.nixvimModules.default =
    # Code intelligence: language server, completion, and diagnostics.
    let
      lspExtraKeymaps = [
        {
          mode = "n";
          key = "gd";
          action.__raw = "function() vim.lsp.buf.definition() end";
          options.desc = "Goto Definition";
        }
        {
          mode = "n";
          key = "gD";
          action.__raw = "function() vim.lsp.buf.declaration() end";
          options.desc = "Goto Declaration";
        }
        {
          mode = "n";
          key = "gy";
          action.__raw = "function() vim.lsp.buf.type_definition() end";
          options.desc = "Goto T[y]pe Definition";
        }
        {
          mode = "n";
          key = "gI";
          action.__raw = "function() vim.lsp.buf.implementation() end";
          options.desc = "Goto Implementation";
        }
        {
          mode = "n";
          key = "gr";
          action.__raw = "function() vim.lsp.buf.references() end";
          options = {
            desc = "References";
            nowait = true;
          };
        }
        {
          mode = "n";
          key = "K";
          action.__raw = "function() vim.lsp.buf.hover() end";
          options.desc = "Hover";
        }
        {
          mode = "n";
          key = "gK";
          action.__raw = "function() vim.lsp.buf.signature_help() end";
          options.desc = "Signature Help";
        }
        {
          mode = [
            "n"
            "x"
          ];
          key = "<leader>ca";
          action.__raw = "function() vim.lsp.buf.code_action() end";
          options.desc = "Code Action";
        }
        {
          mode = "n";
          key = "<leader>cr";
          action.__raw = "function() vim.lsp.buf.rename() end";
          options.desc = "Rename";
        }
        {
          mode = "n";
          key = "<leader>cd";
          action.__raw = "function() vim.diagnostic.open_float() end";
          options.desc = "Line Diagnostics";
        }
        {
          mode = "i";
          key = "<c-k>";
          action.__raw = "function() vim.lsp.buf.signature_help() end";
          options.desc = "Signature Help";
        }
        {
          mode = "n";
          key = "<leader>cl";
          action.__raw = "function() Snacks.picker.lsp_config() end";
          options.desc = "Lsp Info";
        }
        {
          mode = [
            "n"
            "x"
          ];
          key = "<leader>cc";
          action.__raw = "function() vim.lsp.codelens.run() end";
          options.desc = "Run Codelens";
        }
        {
          mode = "n";
          key = "<leader>cC";
          action.__raw = "function() vim.lsp.codelens.refresh() end";
          options.desc = "Refresh & Display Codelens";
        }
        {
          mode = "n";
          key = "<leader>cA";
          action.__raw = "function() vim.lsp.buf.code_action({ context = { only = { 'source' }, diagnostics = {} } }) end";
          options.desc = "Source Action";
        }
        {
          mode = "n";
          key = "<leader>co";
          action.__raw = "function() vim.lsp.buf.code_action({ apply = true, context = { only = { 'source.organizeImports' }, diagnostics = {} } }) end";
          options.desc = "Organize Imports";
        }
        {
          mode = "n";
          key = "gai";
          action.__raw = "function() Snacks.picker.lsp_incoming_calls() end";
          options.desc = "C[a]lls Incoming";
        }
        {
          mode = "n";
          key = "gao";
          action.__raw = "function() Snacks.picker.lsp_outgoing_calls() end";
          options.desc = "C[a]lls Outgoing";
        }
      ];
    in
    {
      # which-key groups
      extraConfigLua = ''
        require("which-key").add({
          { "<leader>c", group = "code" },
          { "<leader>x", group = "diagnostics/quickfix" },
          { "g", group = "goto" },
        })

        -- nvim 0.12 defaults virtual_text off; enable inline diagnostics + nerd-font signs.
        vim.diagnostic.config({
          severity_sort = true,
          virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
          signs = {
            text = {
              [vim.diagnostic.severity.ERROR] = " ",
              [vim.diagnostic.severity.WARN] = " ",
              [vim.diagnostic.severity.HINT] = " ",
              [vim.diagnostic.severity.INFO] = " ",
            },
          },
        })

        local map = vim.keymap.set

        -- Route format through conform (code-languages.nix) so nix/python (whose LSPs don't format) are covered too.
        map({ "n", "x" }, "<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, { desc = "Format" })
        map({ "n", "x" }, "<leader>cF", function() require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 }) end, { desc = "Format Injected Langs" })
        map("n", "<leader>cs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols (Trouble)" })
        map("n", "<leader>cS", "<cmd>Trouble lsp toggle<cr>", { desc = "LSP references/definitions/... (Trouble)" })
        map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
        map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })
        map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
        map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })
        map("n", "<leader>xl", function()
          local ok, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
          if not ok and err then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end, { desc = "Location List" })
        map("n", "<leader>xq", function()
          local ok, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
          if not ok and err then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end, { desc = "Quickfix List" })

        local next_qf, prev_qf = _G.MkRepeatMove(function(forward)
          if require("trouble").is_open() then
            require("trouble")[forward and "next" or "prev"]({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(forward and vim.cmd.cnext or vim.cmd.cprev)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end)
        map("n", "]q", next_qf, { desc = "Next Trouble/Quickfix Item" })
        map("n", "[q", prev_qf, { desc = "Previous Trouble/Quickfix Item" })

        map("n", "<leader>cR", function() Snacks.rename.rename_file() end, { desc = "Rename File" })

        local next_ref, prev_ref = _G.MkRepeatMove(function(forward) Snacks.words.jump(forward and vim.v.count1 or -vim.v.count1) end)
        map("n", "]]", next_ref, { desc = "Next Reference" })
        map("n", "[[", prev_ref, { desc = "Prev Reference" })
        map("n", "<a-n>", function() Snacks.words.jump(vim.v.count1, true) end, { desc = "Next Reference" })
        map("n", "<a-p>", function() Snacks.words.jump(-vim.v.count1, true) end, { desc = "Prev Reference" })

        local next_diag, prev_diag = _G.MkRepeatMove(function(forward) vim.diagnostic.jump({ count = forward and 1 or -1, float = true }) end)
        map("n", "]d", next_diag, { desc = "Next Diagnostic" })
        map("n", "[d", prev_diag, { desc = "Prev Diagnostic" })

        local next_err, prev_err = _G.MkRepeatMove(function(forward) vim.diagnostic.jump({ count = forward and 1 or -1, severity = vim.diagnostic.severity.ERROR, float = true }) end)
        map("n", "]e", next_err, { desc = "Next Error" })
        map("n", "[e", prev_err, { desc = "Prev Error" })

        local next_warn, prev_warn = _G.MkRepeatMove(function(forward) vim.diagnostic.jump({ count = forward and 1 or -1, severity = vim.diagnostic.severity.WARN, float = true }) end)
        map("n", "]w", next_warn, { desc = "Next Warning" })
        map("n", "[w", prev_warn, { desc = "Prev Warning" })

        -- todo-comments
        local next_todo, prev_todo = _G.MkRepeatMove(function(forward) require("todo-comments")[forward and "jump_next" or "jump_prev"]() end)
        map("n", "]t", next_todo, { desc = "Next Todo Comment" })
        map("n", "[t", prev_todo, { desc = "Previous Todo Comment" })
        map("n", "<leader>xt", "<cmd>Trouble todo toggle<cr>", { desc = "Todo (Trouble)" })
        map("n", "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", { desc = "Todo/Fix/Fixme (Trouble)" })
        map("n", "<leader>st", function() Snacks.picker.todo_comments() end, { desc = "Todo" })
        map("n", "<leader>sT", function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end, { desc = "Todo/Fix/Fixme" })
      '';

      plugins.lsp = {
        enable = true;
        inlayHints = true;

        # advertise file-rename support so <leader>cR updates imports across the project
        capabilities = ''
          capabilities.workspace = capabilities.workspace or {}
          capabilities.workspace.fileOperations = { didRename = true, willRename = true }
        '';

        # All bind buffer-local on LspAttach.
        keymaps.extra = lspExtraKeymaps;
      };

      plugins.blink-cmp = {
        enable = true;
        settings = {
          keymap.preset = "enter"; # Enter accepts the selected completion
          completion.documentation.auto_show = true;
        };
      };

      plugins.friendly-snippets.enable = true; # blink's snippets source auto-loads it from the rtp

      plugins.trouble = {
        enable = true;
        settings.modes.lsp.win.position = "right";
      };
      plugins.todo-comments.enable = true;

      plugins.conform-nvim = {
        enable = true;
        autoInstall.enable = true; # bake the formatter packages into the wrapper.
        settings = {
          # Conditional autoformat
          format_on_save.__raw = ''
            function(bufnr)
              if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                return
              end
              return { timeout_ms = 3000, lsp_format = "fallback" }
            end'';
        };
      };

      # Linting layer (diagnostics from external tools); linters wired per-ft in code-languages.nix.
      autoGroups.lint.clear = true;
      plugins.lint = {
        enable = true;
        autoInstall.enable = true; # bake shellcheck (and any lintersByFt linter) into the wrapper
        autoCmd = {
          group = "lint";
          event = [
            "BufWritePost"
            "BufReadPost"
            "InsertLeave"
          ];
        };
      };

    };
}
