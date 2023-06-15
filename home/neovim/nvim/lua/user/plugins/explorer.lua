-- return {
--   "nvim-neo-tree/neo-tree.nvim",
--   dependencies = {
--     "nvim-lua/plenary.nvim",
--     "nvim-tree/nvim-web-devicons",
--     "MunifTanjim/nui.nvim",
--   },
--   cmd = "Neotree",
--   keys = {
--     { "<leader>fe", "<cmd>Neotree toggle<cr>", desc = "NeoTree" },
--   },
--   config = function(_, opts)
--     require("neo-tree").setup(opts)
--   end,
-- }

return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>fe", "<cmd>NvimTreeToggle<cr>", desc = "NvimTree" },
  },
  config = true,
}
