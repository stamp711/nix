{
  flake.nixvimModules.default =
    # Code intelligence: language server, completion, and diagnostics.
    {
      # which-key groups
      extraConfigLua = ''
        do
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

          map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })

          local next_diag, prev_diag = _G.MkRepeatMove(function(forward) vim.diagnostic.jump({ count = (forward and 1 or -1) * vim.v.count1, float = true }) end)
          map("n", "]d", next_diag, { desc = "Next Diagnostic" })
          map("n", "[d", prev_diag, { desc = "Prev Diagnostic" })

          local next_err, prev_err = _G.MkRepeatMove(function(forward) vim.diagnostic.jump({ count = (forward and 1 or -1) * vim.v.count1, severity = vim.diagnostic.severity.ERROR, float = true }) end)
          map("n", "]e", next_err, { desc = "Next Error" })
          map("n", "[e", prev_err, { desc = "Prev Error" })

          local next_warn, prev_warn = _G.MkRepeatMove(function(forward) vim.diagnostic.jump({ count = (forward and 1 or -1) * vim.v.count1, severity = vim.diagnostic.severity.WARN, float = true }) end)
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
        end
      '';

      # Post: plugin setup() shares the extraConfigLua bucket, so run Snacks-dependent code here to guarantee Snacks is ready.
      extraConfigLuaPost = ''
        do
          -- LSP keymaps: capability-gated + buffer-local via Snacks.keymap.set (lsp filter), mirroring LazyVim.
          -- lsp = {} means "any LSP buffer"; lsp = { method } gates on that capability (static + dynamic).
          local sk = Snacks.keymap.set
          local function code_action_kinds(buf)
            local ret = {}
            for _, c in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
              vim.list_extend(ret, vim.tbl_get(c, "server_capabilities", "codeActionProvider", "codeActionKinds") or {})
              for _, reg in ipairs(c.dynamic_capabilities:get("textDocument/codeAction", { bufnr = buf }) or {}) do
                vim.list_extend(ret, vim.tbl_get(reg, "registerOptions", "codeActionKinds") or {})
              end
            end
            return ret
          end

          sk("n", "<leader>cl", function() Snacks.picker.lsp_config() end, { desc = "Lsp Info", lsp = {} })
          sk("n", "gd", function() Snacks.picker.lsp_definitions() end, { desc = "Goto Definition", lsp = { method = "textDocument/definition" } })
          sk("n", "gr", function() Snacks.picker.lsp_references() end, { desc = "References", nowait = true, lsp = {} })
          sk("n", "gI", function() Snacks.picker.lsp_implementations() end, { desc = "Goto Implementation", lsp = {} })
          sk("n", "gy", function() Snacks.picker.lsp_type_definitions() end, { desc = "Goto T[y]pe Definition", lsp = {} })
          sk("n", "gD", vim.lsp.buf.declaration, { desc = "Goto Declaration", lsp = {} })
          sk("n", "K", function() return vim.lsp.buf.hover() end, { desc = "Hover", lsp = {} })
          sk("n", "gK", function() return vim.lsp.buf.signature_help() end, { desc = "Signature Help", lsp = { method = "textDocument/signatureHelp" } })
          sk("i", "<C-s>", function() return vim.lsp.buf.signature_help() end, { desc = "Signature Help", lsp = { method = "textDocument/signatureHelp" } })
          sk({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action", lsp = { method = "textDocument/codeAction" } })
          sk({ "n", "x" }, "<leader>cc", vim.lsp.codelens.run, { desc = "Run Codelens", lsp = { method = "textDocument/codeLens" } })
          sk("n", "<leader>cC", vim.lsp.codelens.refresh, { desc = "Refresh & Display Codelens", lsp = { method = "textDocument/codeLens" } })
          sk("n", "<leader>cR", function() Snacks.rename.rename_file() end, { desc = "Rename File", lsp = { method = "workspace/didRenameFiles" } })
          sk("n", "<leader>cR", function() Snacks.rename.rename_file() end, { desc = "Rename File", lsp = { method = "workspace/willRenameFiles" } })
          sk("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename", lsp = { method = "textDocument/rename" } })
          sk("n", "<leader>cA", function() vim.lsp.buf.code_action({ apply = true, context = { only = { "source" }, diagnostics = {} } }) end, { desc = "Source Action", lsp = { method = "textDocument/codeAction" } })
          sk("n", "]]", function() Snacks.words.jump(vim.v.count1) end, { desc = "Next Reference", lsp = { method = "textDocument/documentHighlight" }, enabled = function() return Snacks.words.is_enabled() end })
          sk("n", "[[", function() Snacks.words.jump(-vim.v.count1) end, { desc = "Prev Reference", lsp = { method = "textDocument/documentHighlight" }, enabled = function() return Snacks.words.is_enabled() end })
          sk("n", "<a-n>", function() Snacks.words.jump(vim.v.count1, true) end, { desc = "Next Reference", lsp = { method = "textDocument/documentHighlight" }, enabled = function() return Snacks.words.is_enabled() end })
          sk("n", "<a-p>", function() Snacks.words.jump(-vim.v.count1, true) end, { desc = "Prev Reference", lsp = { method = "textDocument/documentHighlight" }, enabled = function() return Snacks.words.is_enabled() end })
          sk("n", "<leader>co", function() vim.lsp.buf.code_action({ apply = true, context = { only = { "source.organizeImports" }, diagnostics = {} } }) end, {
            desc = "Organize Imports",
            lsp = { method = "textDocument/codeAction" },
            enabled = function(buf)
              for _, k in ipairs(code_action_kinds(buf)) do
                if k == "source.organizeImports" or k == "source.organizeImports." then
                  return true
                end
              end
              return false
            end,
          })
          sk("n", "gai", function() Snacks.picker.lsp_incoming_calls() end, { desc = "C[a]lls Incoming", lsp = { method = "callHierarchy/incomingCalls" } })
          sk("n", "gao", function() Snacks.picker.lsp_outgoing_calls() end, { desc = "C[a]lls Outgoing", lsp = { method = "callHierarchy/outgoingCalls" } })
        end
      '';

      plugins.lsp = {
        enable = true;
        inlayHints = true;

        # advertise file-rename support so <leader>cR updates imports across the project
        capabilities = ''
          capabilities.workspace = capabilities.workspace or {}
          capabilities.workspace.fileOperations = { didRename = true, willRename = true }
        '';

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
