{
  flake.nixvimModules.default =
    # Version control: signs, hunks, history, and browsing.
    { pkgs, ... }:
    {
      # lazygit binary backing Snacks.lazygit (<leader>gg / gG).
      extraPackages = [ pkgs.lazygit ];

      plugins.gitsigns = {
        enable = true;
        settings = {
          # defaults are too heavy
          signs = {
            add.text = "▎";
            change.text = "▎";
            delete.text = "";
            topdelete.text = "";
            changedelete.text = "▎";
            untracked.text = "▎";
          };
          signs_staged = {
            add.text = "▎";
            change.text = "▎";
            delete.text = "";
            topdelete.text = "";
            changedelete.text = "▎";
          };
        };
      };

      extraConfigLua = ''
        local map = vim.keymap.set
        local gs = require("gitsigns")

        -- which-key groups
        require("which-key").add({
          { "<leader>g", group = "git", mode = { "n", "v" } },
          { "<leader>gh", group = "hunks", mode = { "n", "v" } },
        })

        local function pick(key, desc, src) map("n", key, function() Snacks.picker[src]() end, { desc = desc }) end

        -- Repeatable hunk moves.
        local next_hunk, prev_hunk = _G.MkRepeatMove(function(forward) gs.nav_hunk(forward and "next" or "prev") end)
        map("n", "]h", next_hunk, { desc = "Next Hunk" })
        map("n", "[h", prev_hunk, { desc = "Prev Hunk" })
        map("n", "]H", function() gs.nav_hunk("last") end, { desc = "Last Hunk" })
        map("n", "[H", function() gs.nav_hunk("first") end, { desc = "First Hunk" })

        -- Stage/reset are range-aware via the command, so they cover n + visual.
        map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", { desc = "Stage Hunk" })
        map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", { desc = "Reset Hunk" })
        map("n", "<leader>ghS", function() gs.stage_buffer() end, { desc = "Stage Buffer" })
        map("n", "<leader>ghu", function() gs.undo_stage_hunk() end, { desc = "Undo Stage Hunk" })
        map("n", "<leader>ghR", function() gs.reset_buffer() end, { desc = "Reset Buffer" })
        map("n", "<leader>ghp", function() gs.preview_hunk_inline() end, { desc = "Preview Hunk Inline" })
        map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, { desc = "Blame Line" })
        map("n", "<leader>ghB", function() gs.blame() end, { desc = "Blame Buffer" })
        map("n", "<leader>ghd", function() gs.diffthis() end, { desc = "Diff This" })
        map("n", "<leader>ghD", function() gs.diffthis("~") end, { desc = "Diff This ~" })

        pick("<leader>gd", "Git Diff (hunks)", "git_diff")
        pick("<leader>gs", "Git Status", "git_status")
        pick("<leader>gS", "Git Stash", "git_stash")
        map("n", "<leader>gl", function() Snacks.picker.git_log({ cwd = Root.git() }) end, { desc = "Git Log" })
        pick("<leader>gb", "Git Blame Line", "git_log_line")
        pick("<leader>gf", "Git Current File History", "git_log_file")
        pick("<leader>gi", "GitHub Issues (open)", "gh_issue")
        pick("<leader>gp", "GitHub Pull Requests (open)", "gh_pr")
        pick("<leader>gL", "Git Log (cwd)", "git_log")
        map("n", "<leader>gD", function() Snacks.picker.git_diff({ base = "origin", group = true }) end, { desc = "Git Diff (origin)" })
        map("n", "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, { desc = "GitHub Issues (all)" })
        map("n", "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, { desc = "GitHub Pull Requests (all)" })
        map("n", "<leader>gg", function() Snacks.lazygit({ cwd = Root.git() }) end, { desc = "Lazygit (Root Dir)" })
        map("n", "<leader>gG", function() Snacks.lazygit() end, { desc = "Lazygit (cwd)" })

        map({ "n", "x" }, "<leader>gB", function() Snacks.gitbrowse() end, { desc = "Git Browse (open)" })
        map({ "n", "x" }, "<leader>gY", function() Snacks.gitbrowse({ open = function(url) vim.fn.setreg("+", url) end, notify = false }) end, { desc = "Git Browse (copy)" })
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "GitSigns Select Hunk" })
      '';
    };
}
