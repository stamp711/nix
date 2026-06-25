{
  vim.keymaps = [
    {
      key = "<Esc>";
      mode = "n";
      action = "<cmd>noh<CR>";
      desc = "Clear search highlight";
    }
    {
      key = "<leader>y";
      mode = [
        "n"
        "x"
      ];
      action = "\"+y";
      desc = "Yank to system clipboard";
    }
    {
      key = "<leader>e";
      mode = "n";
      action = "<cmd>Neotree toggle<CR>";
      desc = "Toggle file tree";
    }
    {
      key = "<C-h>";
      mode = "n";
      action = "<C-w>h";
      desc = "Go to left window";
    }
    {
      key = "<C-j>";
      mode = "n";
      action = "<C-w>j";
      desc = "Go to lower window";
    }
    {
      key = "<C-k>";
      mode = "n";
      action = "<C-w>k";
      desc = "Go to upper window";
    }
    {
      key = "<C-l>";
      mode = "n";
      action = "<C-w>l";
      desc = "Go to right window";
    }
  ];
}
