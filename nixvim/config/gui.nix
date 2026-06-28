{
  flake.nixvimModules.default = {
    opts.guifont = "Monaco Nerd Font:h13";
    opts.linespace = 4;

    globals = {
      neovide_cursor_animation_length = 0;
      neovide_scroll_animation_length = 0.1;
      neovide_position_animation_length = 0.1;
      neovide_hide_mouse_when_typing = true;
      # macOS: Option sends Alt so <A-..> mappings fire
      neovide_input_macos_option_key_is_meta = "only_left";
    };

    extraConfigLua = ''
      vim.opt.guicursor:append("a:blinkon0")

      -- Cmd+C/V on macOS
      if vim.g.neovide then
        vim.keymap.set({ "n", "x" }, "<D-c>", '"+y', { desc = "Copy to clipboard" })
        vim.keymap.set({ "n", "x" }, "<D-v>", '"+p', { desc = "Paste from clipboard" })
        vim.keymap.set("i", "<D-v>", "<C-r>+", { desc = "Paste from clipboard" })
        vim.keymap.set("c", "<D-v>", "<C-r>+", { desc = "Paste from clipboard" })
      end
    '';
  };
}
