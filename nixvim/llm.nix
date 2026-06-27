{ inputs, ... }:
{
  flake.nixvimModules.default =
    # LLM: claudecode.nvim (IDE bridge) + sidekick.nvim (NES + CLI) + ThePrimeagen/99 (agent ops).
    # Each tool gets its own <leader>a subgroup (ac/as/a9) to avoid LazyVim's bare-<leader>a collisions.
    { pkgs, ... }:
    let
      nvim-99 = pkgs.vimUtils.buildVimPlugin {
        pname = "99";
        version = inputs.nvim-99.shortRev or "unstable";
        src = inputs.nvim-99;
        # unused upstream WIP module; its require of a missing file only trips the build-time check
        nvimSkipModule = [ "99.editor.lsp" ];
      };
    in
    {
      plugins.claudecode.enable = true;
      plugins.sidekick.enable = true;
      lsp.servers.copilot.enable = true; # sidekick NES (next-edit suggestions) runs off the Copilot LSP

      extraPlugins = [ nvim-99 ];

      extraConfigLua = ''
        require("99").setup({
          provider = require("99").Providers.ClaudeCodeProvider,
          -- 99 always passes --model, so pin it; it can't defer to claude-code's own default
          model = "opus",
          -- native avoids pulling blink.compat just for the prompt's #/@ completion
          completion = { source = "native" },
          md_files = { "CLAUDE.md", "AGENTS.md", "AGENT.md" },
        })

        Snacks.toggle({
          name = "Sidekick NES",
          get = function() return require("sidekick.nes").enabled end,
          set = function(state) require("sidekick.nes").enable(state) end,
        }):map("<leader>uN")

        require("which-key").add({
          { "<leader>a", group = "ai", mode = { "n", "v" } },
          { "<leader>a9", group = "99", mode = { "n", "x" } },
          { "<leader>ac", group = "claudecode", mode = { "n", "x" } },
          { "<leader>as", group = "sidekick", mode = { "n", "x" } },
        })
      '';

      keymaps = [
        # claudecode under <leader>ac (LazyVim's claudecode.lua letters as the 3rd char)
        {
          mode = "n";
          key = "<leader>acc";
          action = "<cmd>ClaudeCode<cr>";
          options.desc = "Toggle Claude";
        }
        {
          mode = "n";
          key = "<leader>acf";
          action = "<cmd>ClaudeCodeFocus<cr>";
          options.desc = "Focus Claude";
        }
        {
          mode = "n";
          key = "<leader>acr";
          action = "<cmd>ClaudeCode --resume<cr>";
          options.desc = "Resume Claude";
        }
        {
          mode = "n";
          key = "<leader>acC";
          action = "<cmd>ClaudeCode --continue<cr>";
          options.desc = "Continue Claude";
        }
        {
          mode = "n";
          key = "<leader>acb";
          action = "<cmd>ClaudeCodeAdd %<cr>";
          options.desc = "Add current buffer";
        }
        {
          mode = "v";
          key = "<leader>acs";
          action = "<cmd>ClaudeCodeSend<cr>";
          options.desc = "Send to Claude";
        }
        {
          mode = "n";
          key = "<leader>aca";
          action = "<cmd>ClaudeCodeDiffAccept<cr>";
          options.desc = "Accept diff";
        }
        {
          mode = "n";
          key = "<leader>acd";
          action = "<cmd>ClaudeCodeDiffDeny<cr>";
          options.desc = "Deny diff";
        }

        # sidekick CLI under <leader>as (LazyVim's sidekick.lua letters as the 3rd char)
        {
          mode = "n";
          key = "<leader>asa";
          action.__raw = ''function() require("sidekick.cli").toggle() end'';
          options.desc = "Toggle CLI";
        }
        {
          mode = "n";
          key = "<leader>ass";
          action.__raw = ''function() require("sidekick.cli").select() end'';
          options.desc = "Select CLI";
        }
        {
          mode = "n";
          key = "<leader>asd";
          action.__raw = ''function() require("sidekick.cli").close() end'';
          options.desc = "Detach Session";
        }
        {
          mode = [
            "n"
            "x"
          ];
          key = "<leader>ast";
          action.__raw = ''function() require("sidekick.cli").send({ msg = "{this}" }) end'';
          options.desc = "Send This";
        }
        {
          mode = "n";
          key = "<leader>asf";
          action.__raw = ''function() require("sidekick.cli").send({ msg = "{file}" }) end'';
          options.desc = "Send File";
        }
        {
          mode = "x";
          key = "<leader>asv";
          action.__raw = ''function() require("sidekick.cli").send({ msg = "{selection}" }) end'';
          options.desc = "Send Selection";
        }
        {
          mode = [
            "n"
            "x"
          ];
          key = "<leader>asp";
          action.__raw = ''function() require("sidekick.cli").prompt() end'';
          options.desc = "Select Prompt";
        }

        # sidekick NES — bare keys, 1:1 LazyVim (no <leader>a collision)
        {
          mode = "n";
          key = "<tab>";
          action.__raw = ''function() if not require("sidekick").nes_jump_or_apply() then return "<Tab>" end end'';
          options = {
            expr = true;
            desc = "Goto/Apply Next Edit Suggestion";
          };
        }
        {
          mode = [
            "n"
            "t"
            "i"
            "x"
          ];
          key = "<c-.>";
          action.__raw = ''function() require("sidekick.cli").focus() end'';
          options.desc = "Sidekick Focus";
        }

        # ThePrimeagen/99 under <leader>a9
        {
          mode = "n";
          key = "<leader>a9s";
          action.__raw = ''function() require("99").search() end'';
          options.desc = "Search";
        }
        {
          mode = "x";
          key = "<leader>a9v";
          action.__raw = ''function() require("99").visual() end'';
          options.desc = "Edit Selection";
        }
        {
          mode = "n";
          key = "<leader>a9x";
          action.__raw = ''function() require("99").stop_all_requests() end'';
          options.desc = "Stop";
        }
      ];
    };
}
