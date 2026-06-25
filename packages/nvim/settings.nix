# nvf vim settings (single source of truth for the nvim package).
# Lua-heavy bits (plugin setup, keymaps) can move to sibling *.lua files and be
# pulled in with builtins.readFile, keeping them stylua-formatted.
{
  vim = {
    theme = {
      enable = true;
      name = "onedark";
      style = "warm";
    };

    options = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      signcolumn = "yes";
    };

    statusline.lualine.enable = true;
    telescope.enable = true;
    treesitter.enable = true;
    binds.whichKey.enable = true;
    autocomplete.blink-cmp.enable = true;
    git.gitsigns.enable = true;
    utility.motion.flash-nvim.enable = true;

    lsp = {
      enable = true;
      formatOnSave = true;
    };

    languages = {
      enableTreesitter = true;
      enableFormat = true;

      clang.enable = true;
      json.enable = true;
      markdown.enable = true;
      nix.enable = true;
      python.enable = true;
      rust.enable = true;
      toml.enable = true;
      zig.enable = true;
    };
  };
}
