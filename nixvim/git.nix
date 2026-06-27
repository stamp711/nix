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

      # which-key groups
      extraConfigLua = ''
        require("which-key").add({
          { "<leader>g", group = "git" },
          { "<leader>gh", group = "hunks" },
        })
      '';

      keymaps =
        let
          nav = key: desc: dir: {
            inherit key;
            mode = "n";
            action.__raw = ''function() require("gitsigns").nav_hunk("${dir}") end'';
            options.desc = desc;
          };
          op = key: desc: call: {
            inherit key;
            mode = "n";
            action.__raw = ''function() require("gitsigns").${call} end'';
            options.desc = desc;
          };
          # Stage/reset are range-aware via the command, so they cover n + visual.
          cmd = key: desc: sub: {
            inherit key;
            mode = [
              "n"
              "x"
            ];
            action = ":Gitsigns ${sub}<CR>";
            options.desc = desc;
          };
          pick = key: desc: src: {
            inherit key;
            mode = "n";
            action.__raw = "function() Snacks.picker.${src}() end";
            options.desc = desc;
          };
        in
        [
          (nav "]h" "Next Hunk" "next")
          (nav "[h" "Prev Hunk" "prev")
          (nav "]H" "Last Hunk" "last")
          (nav "[H" "First Hunk" "first")

          (cmd "<leader>ghs" "Stage Hunk" "stage_hunk")
          (cmd "<leader>ghr" "Reset Hunk" "reset_hunk")
          (op "<leader>ghS" "Stage Buffer" "stage_buffer()")
          (op "<leader>ghu" "Undo Stage Hunk" "undo_stage_hunk()")
          (op "<leader>ghR" "Reset Buffer" "reset_buffer()")
          (op "<leader>ghp" "Preview Hunk Inline" "preview_hunk_inline()")
          (op "<leader>ghb" "Blame Line" "blame_line({ full = true })")
          (op "<leader>ghB" "Blame Buffer" "blame()")
          (op "<leader>ghd" "Diff This" "diffthis()")
          (op "<leader>ghD" "Diff This ~" ''diffthis("~")'')

          (pick "<leader>gd" "Git Diff (hunks)" "git_diff")
          (pick "<leader>gs" "Git Status" "git_status")
          (pick "<leader>gS" "Git Stash" "git_stash")
          {
            key = "<leader>gl";
            mode = "n";
            action.__raw = ''function() Snacks.picker.git_log({ cwd = vim.fs.root(0, ".git") }) end'';
            options.desc = "Git Log";
          }
          (pick "<leader>gb" "Git Blame Line" "git_log_line")
          (pick "<leader>gf" "Git Current File History" "git_log_file")
          (pick "<leader>gi" "GitHub Issues (open)" "gh_issue")
          (pick "<leader>gp" "GitHub Pull Requests (open)" "gh_pr")
          (pick "<leader>gL" "Git Log (cwd)" "git_log")
          {
            key = "<leader>gD";
            mode = "n";
            action.__raw = ''function() Snacks.picker.git_diff({ base = "origin", group = true }) end'';
            options.desc = "Git Diff (origin)";
          }
          {
            key = "<leader>gI";
            mode = "n";
            action.__raw = ''function() Snacks.picker.gh_issue({ state = "all" }) end'';
            options.desc = "GitHub Issues (all)";
          }
          {
            key = "<leader>gP";
            mode = "n";
            action.__raw = ''function() Snacks.picker.gh_pr({ state = "all" }) end'';
            options.desc = "GitHub Pull Requests (all)";
          }
          {
            key = "<leader>gg";
            mode = "n";
            action.__raw = ''function() Snacks.lazygit({ cwd = vim.fs.root(0, ".git") }) end'';
            options.desc = "Lazygit (Root Dir)";
          }
          {
            key = "<leader>gG";
            mode = "n";
            action.__raw = "function() Snacks.lazygit() end";
            options.desc = "Lazygit (cwd)";
          }

          {
            key = "<leader>gB";
            mode = [
              "n"
              "x"
            ];
            action.__raw = "function() Snacks.gitbrowse() end";
            options.desc = "Git Browse (open)";
          }
          {
            key = "<leader>gY";
            mode = [
              "n"
              "x"
            ];
            action.__raw = ''function() Snacks.gitbrowse({ open = function(url) vim.fn.setreg("+", url) end, notify = false }) end'';
            options.desc = "Git Browse (copy)";
          }
          {
            key = "ih";
            mode = [
              "o"
              "x"
            ];
            action = ":<C-U>Gitsigns select_hunk<CR>";
            options.desc = "GitSigns Select Hunk";
          }
        ];
    };
}
