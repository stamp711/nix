{
  flake.nixvimModules.default =
    # In-buffer movement & text manipulation.
    #
    # nvim-treesitter `main` binds no textobject keys. Moves are bound buffer-local in
    # extraConfigLua (LazyVim's way) so the global ]a/[a arglist survive; swaps + f/F/t/T
    # are in the keymaps list. `;`/`,` repeat the last move, so f/F/t/T are recording
    # variants and flash char-mode is off (maplocalleader = \ in options.nix).
    {
      # which-key textobject labels
      extraConfigLua = ''
        require("which-key").add({
          { "gs", group = "surround", mode = { "n", "x" } },
          {
            mode = { "o", "x" },
            { "a", group = "around" },
            { "i", group = "inside" },
            { "af", desc = "function" },
            { "if", desc = "function" },
            { "ac", desc = "class" },
            { "ic", desc = "class" },
            { "ao", desc = "block/loop/cond" },
            { "io", desc = "block/loop/cond" },
            { "aa", desc = "argument" },
            { "ia", desc = "argument" },
            { "at", desc = "tag" },
            { "it", desc = "tag" },
            { "ad", desc = "digit" },
            { "id", desc = "digit" },
            { "ae", desc = "word" },
            { "ie", desc = "word" },
            { "ag", desc = "buffer" },
            { "ig", desc = "buffer" },
            { "au", desc = "call" },
            { "iu", desc = "call" },
            { "aU", desc = "call" },
            { "iU", desc = "call" },
          },
        })

        -- mini.pairs only inspects the neighbor char; add LazyVim's four "don't auto-close"
        -- cases by wrapping its open() (verbatim from LazyVim util/mini.lua).
        do
          -- next-char classes after which we skip closing: word, ' [ " . ` $
          local skip_next = [=[[%w%%%'%[%"%.%`%$]]=]
          local skip_ts = { "string" } -- treesitter node types to skip auto-pairing inside
          local skip_unbalanced = true
          local markdown = true
          local pairs = require("mini.pairs")
          local open = pairs.open
          pairs.open = function(pair, neigh_pattern)
            if vim.fn.getcmdline() ~= "" then return open(pair, neigh_pattern) end
            local o, c = pair:sub(1, 1), pair:sub(2, 2)
            local line = vim.api.nvim_get_current_line()
            local cursor = vim.api.nvim_win_get_cursor(0)
            local next = line:sub(cursor[2] + 1, cursor[2] + 1)
            local before = line:sub(1, cursor[2])
            -- typing the third backtick at line start expands to a fenced code block
            if markdown and o == "`" and vim.bo.filetype == "markdown" and before:match("^%s*``") then
              return "`\n```" .. vim.api.nvim_replace_termcodes("<up>", true, true, true)
            end
            -- about to type in front of a word/quote/etc: insert only the opening char
            if skip_next and next ~= "" and next:match(skip_next) then return o end
            -- cursor sits inside a string (or other listed) treesitter node: don't close
            if skip_ts and #skip_ts > 0 then
              local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, cursor[1] - 1, math.max(cursor[2] - 1, 0))
              for _, capture in ipairs(ok and captures or {}) do
                if vim.tbl_contains(skip_ts, capture.capture) then return o end
              end
            end
            -- line already has more closers than openers: don't add another
            if skip_unbalanced and next == c and c ~= o then
              local _, count_open = line:gsub(vim.pesc(pair:sub(1, 1)), "")
              local _, count_close = line:gsub(vim.pesc(pair:sub(2, 2)), "")
              if count_close > count_open then return o end
            end
            return open(pair, neigh_pattern)
          end
        end

        -- Treesitter moves, bound buffer-local (LazyVim's way) so the global arglist ]a/[a survive.
        do
          local moves = {
            goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
            goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
            goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
            goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
          }
          local function have(ft)
            local lang = vim.treesitter.language.get_lang(ft)
            return lang ~= nil and vim.treesitter.query.get(lang, "textobjects") ~= nil
          end
          local function attach(buf)
            if not have(vim.bo[buf].filetype) then return end
            for method, keys in pairs(moves) do
              for key, query in pairs(keys) do
                local part = query:gsub("@", ""):gsub("%..*", "")
                part = part:sub(1, 1):upper() .. part:sub(2)
                local desc = (key:sub(1, 1) == "[" and "Prev " or "Next ") .. part
                desc = desc .. (key:sub(2, 2) == key:sub(2, 2):upper() and " End" or " Start")
                vim.keymap.set({ "n", "x", "o" }, key, function()
                  if vim.wo.diff and key:find("[cC]") then return vim.cmd("normal! " .. key) end
                  require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
                end, { buffer = buf, desc = desc, silent = true })
              end
            end
          end
          vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("nvim_ts_moves", { clear = true }),
            callback = function(ev) attach(ev.buf) end,
          })
          vim.tbl_map(attach, vim.api.nvim_list_bufs())
        end
      '';

      plugins = {
        treesitter = {
          enable = true;
          highlight.enable = true;
          indent.enable = true;
          folding.enable = true;
        };
        treesitter-textobjects.enable = true;
        ts-comments.enable = true;

        mini-pairs = {
          enable = true;
          settings.modes = {
            insert = true;
            command = true;
            terminal = false;
          };
        };

        mini-surround = {
          enable = true;
          # gs prefix (LazyVim's scheme); mini's `s` default would clobber flash's s.
          settings.mappings = {
            add = "gsa";
            delete = "gsd";
            find = "gsf";
            find_left = "gsF";
            highlight = "gsh";
            replace = "gsr";
            update_n_lines = "gsn";
          };
        };

        flash = {
          enable = true;
          settings.modes.char.enabled = false;
        };

        mini-ai = {
          enable = true;
          settings.n_lines = 500;
          # f/c/o via treesitter; t/d/e/g/u/U are LazyVim's extras. (copied from LazyVim)
          settings.custom_textobjects = {
            f.__raw = ''require("mini.ai").gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" })'';
            c.__raw = ''require("mini.ai").gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" })'';
            o.__raw = ''
              require("mini.ai").gen_spec.treesitter({
                a = { "@block.outer", "@conditional.outer", "@loop.outer" },
                i = { "@block.inner", "@conditional.inner", "@loop.inner" },
              })'';
            t.__raw = ''{ "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }'';
            d.__raw = ''{ "%f[%d]%d+" }'';
            e.__raw = ''
              {
                { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
                "^().*()$",
              }'';
            # g (whole buffer): inlined verbatim from LazyVim's ai_buffer (lua/lazyvim/util/mini.lua).
            g.__raw = ''
              function(ai_type)
                local start_line, end_line = 1, vim.fn.line("$")
                if ai_type == "i" then
                  local first_nonblank, last_nonblank = vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
                  if first_nonblank == 0 or last_nonblank == 0 then
                    return { from = { line = start_line, col = 1 } }
                  end
                  start_line, end_line = first_nonblank, last_nonblank
                end
                local to_col = math.max(vim.fn.getline(end_line):len(), 1)
                return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
              end'';
            u.__raw = ''require("mini.ai").gen_spec.function_call()'';
            U.__raw = ''require("mini.ai").gen_spec.function_call({ name_pattern = "[%w_]" })'';
          };
        };
      };

      keymaps =
        let
          nxo = [
            "n"
            "x"
            "o"
          ];

          flashKey = key: desc: fn: mode: {
            inherit key mode;
            action.__raw = ''function() require("flash").${fn}() end'';
            options.desc = desc;
          };

          rep = key: desc: fn: {
            inherit key;
            mode = nxo;
            action.__raw = ''require("nvim-treesitter-textobjects.repeatable_move").${fn}'';
            options.desc = desc;
          };

          expr = key: fn: {
            inherit key;
            mode = nxo;
            action.__raw = ''require("nvim-treesitter-textobjects.repeatable_move").${fn}'';
            options.expr = true;
          };
        in
        [
          (flashKey "s" "Flash" "jump" nxo)
          (flashKey "S" "Flash Treesitter" "treesitter" [
            "n"
            "o"
            "x"
          ])
          (flashKey "r" "Remote Flash" "remote" [ "o" ])
          (flashKey "R" "Treesitter Search" "treesitter_search" [
            "o"
            "x"
          ])
          {
            key = "<c-s>";
            mode = "c";
            action.__raw = ''function() require("flash").toggle() end'';
            options.desc = "Toggle Flash Search";
          }
          {
            key = "<c-space>";
            mode = [
              "n"
              "o"
              "x"
            ];
            action.__raw = ''
              function()
                require("flash").treesitter({
                  actions = {
                    ["<c-space>"] = "next",
                    ["<BS>"] = "prev",
                  },
                })
              end'';
            options.desc = "Treesitter Incremental Selection";
          }

          (rep ";" "Repeat last move forward" "repeat_last_move_next")
          (rep "," "Repeat last move backward" "repeat_last_move_previous")

          (expr "f" "builtin_f_expr")
          (expr "F" "builtin_F_expr")
          (expr "t" "builtin_t_expr")
          (expr "T" "builtin_T_expr")
        ];
    };
}
