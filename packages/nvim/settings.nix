{ lib, ... }: {
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
      scrolloff = 8;
      cursorline = true;
      splitright = true;
      splitbelow = true;
    };

    autocmds = [
      {
        event = [
          "FocusGained"
          "TermClose"
          "TermLeave"
        ];
        desc = "Reload buffer if the file changed externally";
        callback = lib.generators.mkLuaInline ''
          function()
            if vim.o.buftype ~= "nofile" then
              vim.cmd("checktime")
            end
          end
        '';
      }
    ];

    statusline.lualine.enable = true;
    telescope.enable = true;
    treesitter.enable = true;
    binds.whichKey.enable = true;
    autocomplete.blink-cmp.enable = true;
    git.gitsigns.enable = true;
    utility.motion.flash-nvim.enable = true;
    utility.surround.enable = true;
    utility.oil-nvim.enable = true;
    autopairs.nvim-autopairs.enable = true;

    tabline.nvimBufferline = {
      enable = true;
      mappings = {
        cyclePrevious = "H";
        cycleNext = "L";
      };
      setupOpts.options.always_show_bufferline = false;
    };
    filetree.neo-tree.enable = true;
    utility.outline.aerial-nvim.enable = true;
    ui.noice.enable = true;

    navigation.harpoon = {
      enable = true;
      mappings = {
        file1 = "<leader>1";
        file2 = "<leader>2";
        file3 = "<leader>3";
        file4 = "<leader>4";
      };
    };

    lsp = {
      enable = true;
      formatOnSave = true;
      inlayHints.enable = true;
      trouble.enable = true;
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
