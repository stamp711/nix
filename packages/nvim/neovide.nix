# vim.g.neovide_* and guifont are inert in the TUI, so GUI and TUI share one config.
{
  opts.guifont = "Monaco Nerd Font:h13";

  globals = {
    neovide_cursor_animation_length = 0;
    neovide_position_animation_length = 0.1;
    neovide_hide_mouse_when_typing = true;
  };
}
