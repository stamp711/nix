{
  flake.nixvimModules.default =
    # File manager: yazi.nvim (floating TUI). Root-dir / cwd, mirroring the find-files keys.
    {
      plugins.yazi.enable = true; # bakes the yazi binary via the module's `yazi` dependency

      keymaps = [
        {
          mode = "n";
          key = "<leader>fy";
          action.__raw = ''function() require("yazi").yazi() end'';
          options.desc = "Yazi (current file)";
        }
        {
          mode = "n";
          key = "<leader>fY";
          action.__raw = ''function() require("yazi").yazi(nil, vim.fn.getcwd()) end'';
          options.desc = "Yazi (cwd)";
        }
      ];
    };
}
