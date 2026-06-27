{
  flake.nixvimModules.default = {

    plugins.claudecode.enable = true;

    extraConfigLua = ''
      -- claudecode.nvim under <leader>ac
      require("which-key").add({
        { "<leader>ac", group = "claudecode", mode = { "n", "x" } },
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
    ];

  };
}
