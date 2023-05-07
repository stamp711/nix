return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  cmd = "Neotree",
  keys = {
    { "<leader>fe", "<cmd>Neotree toggle<cr>", desc = "NeoTree" },
  },
  config = function(_, opts)
    require("neo-tree").setup(opts)
  end,
}
