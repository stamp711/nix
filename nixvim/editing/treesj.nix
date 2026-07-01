{
  flake.nixvimModules.default = {

    plugins.treesj = {
      enable = true;
      settings.use_default_keymaps = false; # <space>s/j/m clash with the <leader>s picker group
    };

    keymaps = [
      {
        mode = "n";
        key = "gS";
        action.__raw = ''function() require("treesj").toggle() end'';
        options.desc = "Split/Join Toggle";
      }
    ];

  };
}
