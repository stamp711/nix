# Project-level: finding, sessions, and marks.
{
  # which-key groups
  extraConfigLua = ''
    require("which-key").add({
      { "<leader>f", group = "file/find" },
      { "<leader>s", group = "search" },
    })
  '';

  plugins.snacks = {
    enable = true;
    settings.picker.enabled = true;
  };

  # snacks bundles neither; grep needs ripgrep, files prefers fd.
  dependencies = {
    ripgrep.enable = true;
    fd.enable = true;
  };

  plugins.oil.enable = true;

  plugins.grug-far = {
    enable = true;
    settings.headerMaxWidth = 80;
  };

  # harpoon2; enable auto-runs setup. Its keymaps option was removed, so bind the List API directly.
  plugins.harpoon.enable = true;

  plugins.persistence.enable = true;

  keymaps =
    let
      # LazyVim's root spec { "lsp", { ".git", "lua" }, "cwd" }: lsp root, else marker, else cwd.
      root = ''
        (function()
          for _, c in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
            if c.root_dir then return c.root_dir end
          end
          return vim.fs.root(0, { ".git", "lua" }) or vim.fn.getcwd()
        end)()'';
      # snacks calls live-grep `grep`.
      pick = key: desc: src: {
        inherit key;
        mode = "n";
        action.__raw = "function() Snacks.picker.${src}() end";
        options.desc = desc;
      };
      pickRoot = key: desc: src: {
        inherit key;
        mode = "n";
        action.__raw = "function() Snacks.picker.${src}({ cwd = ${root} }) end";
        options.desc = desc;
      };
      pickCwd = key: desc: src: {
        inherit key;
        mode = "n";
        action.__raw = "function() Snacks.picker.${src}({ cwd = vim.fn.getcwd() }) end";
        options.desc = desc;
      };
    in
    [
      (pickRoot "<leader><space>" "Find Files (Root Dir)" "files")
      (pick "<leader>," "Buffers" "buffers")
      (pickRoot "<leader>/" "Grep (Root Dir)" "grep")
      (pickRoot "<leader>ff" "Find Files (Root Dir)" "files")
      (pick "<leader>fb" "Buffers" "buffers")
      (pick "<leader>fr" "Recent" "recent")
      (pick "<leader>fg" "Find Files (git-files)" "git_files")
      (pickRoot "<leader>sg" "Grep (Root Dir)" "grep")
      (pick "<leader>sd" "Diagnostics" "diagnostics")
      (pick "<leader>sh" "Help Pages" "help")
      (pick "<leader>sk" "Keymaps" "keymaps")
      (pick "<leader>sR" "Resume" "resume")
      (pick "<leader>ss" "LSP Symbols" "lsp_symbols")
      (pick "<leader>sS" "LSP Workspace Symbols" "lsp_workspace_symbols")
      (pick "<leader>sb" "Buffer Lines" "lines")
      (pick "<leader>sB" "Grep Open Buffers" "grep_buffers")
      (pick "<leader>sc" "Command History" "command_history")
      (pick "<leader>sC" "Commands" "commands")
      (pick "<leader>sD" "Buffer Diagnostics" "diagnostics_buffer")
      (pick "<leader>sH" "Highlights" "highlights")
      (pick "<leader>si" "Icons" "icons")
      (pick "<leader>sj" "Jumps" "jumps")
      (pick "<leader>sl" "Location List" "loclist")
      (pick "<leader>sM" "Man Pages" "man")
      (pick "<leader>sm" "Marks" "marks")
      (pick "<leader>sq" "Quickfix List" "qflist")
      (pick "<leader>su" "Undotree" "undo")
      (pick "<leader>sa" "Autocmds" "autocmds")
      (pick "<leader>s\"" "Registers" "registers")
      (pick "<leader>s/" "Search History" "search_history")
      (pick "<leader>:" "Command History" "command_history")
      (pick "<leader>fp" "Projects" "projects")
      (pickCwd "<leader>fF" "Find Files (cwd)" "files")
      (pickCwd "<leader>sG" "Grep (cwd)" "grep")
      {
        key = "<leader>sW";
        mode = [
          "n"
          "x"
        ];
        action.__raw = "function() Snacks.picker.grep_word({ cwd = vim.fn.getcwd() }) end";
        options.desc = "Visual selection or word (cwd)";
      }
      {
        key = "<leader>fR";
        mode = "n";
        action.__raw = "function() Snacks.picker.recent({ filter = { cwd = true } }) end";
        options.desc = "Recent (cwd)";
      }
      {
        key = "<leader>fB";
        mode = "n";
        action.__raw = "function() Snacks.picker.buffers({ hidden = true, nofile = true }) end";
        options.desc = "Buffers (all)";
      }
      {
        key = "<leader>fc";
        mode = "n";
        action.__raw = ''function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end'';
        options.desc = "Find Config File";
      }
      {
        key = "<leader>ft";
        mode = "n";
        action.__raw = "function() Snacks.terminal(nil, { cwd = ${root} }) end";
        options.desc = "Terminal (Root Dir)";
      }
      {
        key = "<leader>fT";
        mode = "n";
        action.__raw = "function() Snacks.terminal() end";
        options.desc = "Terminal (cwd)";
      }
      {
        key = "<leader>sw";
        mode = [
          "n"
          "x"
        ];
        action.__raw = "function() Snacks.picker.grep_word() end";
        options.desc = "Visual selection or word (Root Dir)";
      }
      {
        key = "<leader>sr";
        mode = [
          "n"
          "x"
        ];
        action.__raw = ''
          function()
            local grug = require("grug-far")
            local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
            grug.open({
              transient = true,
              prefills = { filesFilter = ext and ext ~= "" and "*." .. ext or nil },
            })
          end'';
        options.desc = "Search and Replace";
      }

      # Harpoon
      {
        key = "<leader>H";
        mode = "n";
        action.__raw = "function() require'harpoon':list():add() end";
        options.desc = "Harpoon Add File";
      }
      {
        key = "<leader>h";
        mode = "n";
        action.__raw = "function() require'harpoon'.ui:toggle_quick_menu(require'harpoon':list()) end";
        options.desc = "Harpoon Menu";
      }
      {
        key = "<C-1>";
        mode = "n";
        action.__raw = "function() require'harpoon':list():select(1) end";
        options.desc = "Harpoon File 1";
      }
      {
        key = "<C-2>";
        mode = "n";
        action.__raw = "function() require'harpoon':list():select(2) end";
        options.desc = "Harpoon File 2";
      }
      {
        key = "<C-3>";
        mode = "n";
        action.__raw = "function() require'harpoon':list():select(3) end";
        options.desc = "Harpoon File 3";
      }
      {
        key = "<C-4>";
        mode = "n";
        action.__raw = "function() require'harpoon':list():select(4) end";
        options.desc = "Harpoon File 4";
      }

      # Session (persistence)
      {
        key = "<leader>qs";
        mode = "n";
        action.__raw = ''function() require("persistence").load() end'';
        options.desc = "Restore Session";
      }
      {
        key = "<leader>qS";
        mode = "n";
        action.__raw = ''function() require("persistence").select() end'';
        options.desc = "Select Session";
      }
      {
        key = "<leader>ql";
        mode = "n";
        action.__raw = ''function() require("persistence").load({ last = true }) end'';
        options.desc = "Restore Last Session";
      }
      {
        key = "<leader>qd";
        mode = "n";
        action.__raw = ''function() require("persistence").stop() end'';
        options.desc = "Don't Save Current Session";
      }
    ];
}
