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
      plugins.lint = {
        enable = true;
        autoInstall.enable = true; # bake shellcheck (and any lintersByFt linter) into the wrapper
        autoCmd.event = [
          "BufWritePost"
          "BufReadPost"
          "InsertLeave"
        ];
      };

      # Route format through conform (code-languages.nix) so nix/python (whose LSPs don't format) are covered too.
      keymaps = [
        {
          mode = [
            "n"
            "x"
          ];
          key = "<leader>cf";
          action.__raw = "function() require('conform').format({ async = true, lsp_format = 'fallback' }) end";
          options.desc = "Format";
        }
        {
          mode = [
            "n"
            "x"
          ];
          key = "<leader>cF";
          action.__raw = ''function() require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 }) end'';
          options.desc = "Format Injected Langs";
        }
        {
          mode = "n";
          key = "<leader>cs";
          action = "<cmd>Trouble symbols toggle<cr>";
          options.desc = "Symbols (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>cS";
          action = "<cmd>Trouble lsp toggle<cr>";
          options.desc = "LSP references/definitions/... (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>xx";
          action = "<cmd>Trouble diagnostics toggle<cr>";
          options.desc = "Diagnostics (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>xX";
          action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
          options.desc = "Buffer Diagnostics (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>xL";
          action = "<cmd>Trouble loclist toggle<cr>";
          options.desc = "Location List (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>xQ";
          action = "<cmd>Trouble qflist toggle<cr>";
          options.desc = "Quickfix List (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>xl";
          action.__raw = ''
            function()
              local ok, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
              if not ok and err then
                vim.notify(err, vim.log.levels.ERROR)
              end
            end'';
          options.desc = "Location List";
        }
        {
          mode = "n";
          key = "<leader>xq";
          action.__raw = ''
            function()
              local ok, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
              if not ok and err then
                vim.notify(err, vim.log.levels.ERROR)
              end
            end'';
          options.desc = "Quickfix List";
        }
        {
          mode = "n";
          key = "]q";
          action.__raw = ''
            function()
              if require("trouble").is_open() then
                require("trouble").next({ skip_groups = true, jump = true })
              else
                local ok, err = pcall(vim.cmd.cnext)
                if not ok then
                  vim.notify(err, vim.log.levels.ERROR)
                end
              end
            end'';
          options.desc = "Next Trouble/Quickfix Item";
        }
        {
          mode = "n";
          key = "[q";
          action.__raw = ''
            function()
              if require("trouble").is_open() then
                require("trouble").prev({ skip_groups = true, jump = true })
              else
                local ok, err = pcall(vim.cmd.cprev)
                if not ok then
                  vim.notify(err, vim.log.levels.ERROR)
                end
              end
            end'';
          options.desc = "Previous Trouble/Quickfix Item";
        }
        {
          mode = "n";
          key = "<leader>cR";
          action.__raw = "function() Snacks.rename.rename_file() end";
          options.desc = "Rename File";
        }
        {
          mode = "n";
          key = "]]";
          action.__raw = "function() Snacks.words.jump(vim.v.count1) end";
          options.desc = "Next Reference";
        }
        {
          mode = "n";
          key = "[[";
          action.__raw = "function() Snacks.words.jump(-vim.v.count1) end";
          options.desc = "Prev Reference";
        }
        {
          mode = "n";
          key = "<a-n>";
          action.__raw = "function() Snacks.words.jump(vim.v.count1, true) end";
          options.desc = "Next Reference";
        }
        {
          mode = "n";
          key = "<a-p>";
          action.__raw = "function() Snacks.words.jump(-vim.v.count1, true) end";
          options.desc = "Prev Reference";
        }
        {
          mode = "n";
          key = "]d";
          action.__raw = "function() vim.diagnostic.jump({ count = 1, float = true }) end";
          options.desc = "Next Diagnostic";
        }
        {
          mode = "n";
          key = "[d";
          action.__raw = "function() vim.diagnostic.jump({ count = -1, float = true }) end";
          options.desc = "Prev Diagnostic";
        }
        {
          mode = "n";
          key = "]e";
          action.__raw = "function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true }) end";
          options.desc = "Next Error";
        }
        {
          mode = "n";
          key = "[e";
          action.__raw = "function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true }) end";
          options.desc = "Prev Error";
        }
        {
          mode = "n";
          key = "]w";
          action.__raw = "function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN, float = true }) end";
          options.desc = "Next Warning";
        }
        {
          mode = "n";
          key = "[w";
          action.__raw = "function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN, float = true }) end";
          options.desc = "Prev Warning";
        }

        # todo-comments
        {
          mode = "n";
          key = "]t";
          action.__raw = "function() require('todo-comments').jump_next() end";
          options.desc = "Next Todo Comment";
        }
        {
          mode = "n";
          key = "[t";
          action.__raw = "function() require('todo-comments').jump_prev() end";
          options.desc = "Previous Todo Comment";
        }
        {
          mode = "n";
          key = "<leader>xt";
          action = "<cmd>Trouble todo toggle<cr>";
          options.desc = "Todo (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>xT";
          action = "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>";
          options.desc = "Todo/Fix/Fixme (Trouble)";
        }
        {
          mode = "n";
          key = "<leader>st";
          action.__raw = "function() Snacks.picker.todo_comments() end";
          options.desc = "Todo";
        }
        {
          mode = "n";
          key = "<leader>sT";
          action.__raw = ''function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end'';
          options.desc = "Todo/Fix/Fixme";
        }
      ];
    };
}
