return {
  "f-person/auto-dark-mode.nvim",
  {
    "sainnhe/everforest",
    lazy = false,    -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      vim.g.everforest_transparent_background = 1
      vim.cmd([[colorscheme everforest]])
    end,
  },
  -- {
  --   "xiyaowong/transparent.nvim",
  --   opts = {
  --     extra_groups = {
  --       "NormalFloat", -- plugins which have float panel such as Lazy, Mason, LspInfo
  --       "NvimTreeNormal", -- NvimTree
  --     },
  --   }
  -- }
}
