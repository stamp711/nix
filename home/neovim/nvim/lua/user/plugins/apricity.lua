return {
  { "folke/lazy.nvim", version = "*" },

  { "wakatime/vim-wakatime", event = "VeryLazy" },

  { "nmac427/guess-indent.nvim", opts = {} },

  "f-person/auto-dark-mode.nvim",

  {
    "sainnhe/everforest",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      vim.g.everforest_transparent_background = 1
      vim.cmd([[colorscheme everforest]])
    end,
  },

  {
    "svermeulen/text-to-colorscheme.nvim",
    event = "VeryLazy",
    config = function()
      require("text-to-colorscheme").setup({
        ai = {
          openai_api_key = os.getenv("OPENAI_API_KEY"),
          gpt_model = "gpt-3.5-turbo-0613",
        },
      })
    end,
  },

  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local config = require("alpha.themes.startify").config
      require("alpha").setup(config)
    end,
  },

  { "nvim-lualine/lualine.nvim", event = "VeryLazy", opts = {} },

  {
    "nvim-tree/nvim-tree.lua",
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {},
    keys = {
      { "<leader>fe", "<cmd>NvimTreeToggle<cr>", desc = "NvimTree" },
    },
  },

  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {},
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
      require("which-key").setup({})
    end,
  },

  {
    "folke/noice.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("notify").setup({
        background_colour = "#000000",
      })
      require("noice").setup({
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true,
          },
        },
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
          inc_rename = true,
          lsp_doc_border = true,
        },
      })
    end,
  },

  -- Motion

  {
    "ggandor/leap.nvim",
    dependencies = "tpope/vim-repeat",
    config = function()
      require("leap").add_default_mappings()
    end,
  },

  {
    "ggandor/flit.nvim",
    dependencies = "ggandor/leap.nvim",
    opts = {},
  },

  {
    "LeonHeidelbach/trailblazer.nvim",
    opts = {
      auto_save_trailblazer_state_on_exit = true,
      auto_load_trailblazer_state_on_enter = true,
    },
  },

  -- Telescope & related

  {
    "nvim-telescope/telescope.nvim",

    dependencies = {
      "nvim-lua/plenary.nvim",

      "prochri/telescope-all-recent.nvim",
      "kkharji/sqlite.lua",

      "danielfalk/smart-open.nvim",
      "nvim-telescope/telescope-fzy-native.nvim",

      "nvim-telescope/telescope-file-browser.nvim",
      "nvim-tree/nvim-web-devicons",

      "tsakirist/telescope-lazy.nvim",

      "natecraddock/telescope-zf-native.nvim",
    },

    version = "*",
    cmd = "Telescope",
    keys = {
      { "<leader>fb", "<cmd>Telescope file_browser<cr>", desc = "🔭 file browser" },
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "🔭 find files" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "🔭 oldfiles" },
    },
    config = function()
      local t = require("telescope")
      t.load_extension("zf-native")
      t.load_extension("smart_open")
      t.load_extension("lazy")
      t.load_extension("file_browser")
      -- hack to apply frecency sorting to telescope pickers
      require("telescope-all-recent").setup({})
    end,
  },

  -- Editor

  { "lewis6991/gitsigns.nvim", opts = {} },

  {
    "RRethy/vim-illuminate",
    opts = {},
    config = function(_, opts)
      require("illuminate").configure(opts)
    end,
  },
}
