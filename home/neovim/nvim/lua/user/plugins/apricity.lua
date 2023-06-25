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

  -- LSP & coding

  { "numToStr/Comment.nvim", opts = {} },

  {
    "folke/trouble.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {},
  },

  { "williamboman/mason.nvim", cmd = "Mason", opts = {} },

  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = "nvim-treesitter/nvim-treesitter-textobjects",
    event = { "BufReadPost", "BufNewFile" },
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "markdown",
          "markdown_inline",
        },
      })
    end,
  },

  {
    "glepnir/lspsaga.nvim",
    event = "LspAttach",
    opts = {},
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      -- requires markdown and markdown_inline parser
      "nvim-treesitter/nvim-treesitter",
      "neovim/nvim-lspconfig",
    },
    keys = {
      { "gd", "<cmd>Lspsaga goto_definition<CR>", desc = "goto definition" },
    },
  },

  {
    "kevinhwang91/nvim-ufo",
    dependencies = {
      "kevinhwang91/promise-async",
      "nvim-treesitter",
      "anuvyklack/pretty-fold.nvim",
    },
    config = function()
      -- persistent folds
      local save_fold = vim.api.nvim_create_augroup("Persistent Folds", { clear = true })
      vim.api.nvim_create_autocmd("BufWinLeave", {
        group = save_fold,
        pattern = "*.*",
        callback = function()
          vim.cmd.mkview()
        end,
      })
      vim.api.nvim_create_autocmd("BufWinEnter", {
        group = save_fold,
        pattern = "*.*",
        callback = function()
          vim.cmd.loadview({ mods = { emsg_silent = true } })
        end,
      })

      vim.o.foldcolumn = "0" -- '0' is not bad
      vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true

      -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
      vim.keymap.set("n", "zR", require("ufo").openAllFolds)
      vim.keymap.set("n", "zM", require("ufo").closeAllFolds)

      -- Option 3: treesitter as a main provider instead
      -- Only depend on `nvim-treesitter/queries/filetype/folds.scm`,
      -- performance and stability are better than `foldmethod=nvim_treesitter#foldexpr()`
      require("ufo").setup({
        provider_selector = function()
          return { "treesitter", "indent" }
        end,
      })

      require("pretty-fold").setup({
        fill_char = "·",
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "nvim-cmp",

      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "jose-elias-alvarez/null-ls.nvim",
      "jay-babu/mason-null-ls.nvim",
      "simrat39/rust-tools.nvim",
    },
    -- TODO: write the setup function which takes opts merged from different files (for different languages)
    -- refer: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/lang/typescript.lua
    opts = {},
    config = function()
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

      -- format on save setup callback
      local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
      local on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
          vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ async = false })
            end,
          })
        end
      end

      local server_settings = {
        lua_ls = {
          Lua = {
            runtime = {
              -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
              version = "LuaJIT",
            },
            diagnostics = {
              -- Get the language server to recognize the `vim` global
              globals = { "vim" },
            },
            workspace = {
              -- Make the server aware of Neovim runtime files
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = {
              enable = false,
            },
          },
        },
      }

      -- mason-lspconfig
      local mlsp = require("mason-lspconfig")
      mlsp.setup({
        automatic_installation = true,
        ensure_installed = { "lua_ls", "rust_analyzer" },
        handlers = {
          function(server_name)
            require("lspconfig")[server_name].setup({
              capabilities = capabilities,
              on_attach = on_attach,
              settings = server_settings[server_name],
            })
          end,

          -- rust_analyzer override
          ["rust_analyzer"] = function()
            require("rust-tools").setup({
              server = {
                capabilities = capabilities,
                on_attach = on_attach,
              },
            })
          end,
        },
      })

      -- null-ls
      require("null-ls").setup()
      require("mason-null-ls").setup({
        automatic_installation = true,
        automatic_setup = true,
        ensure_installed = { "stylua" },
        handlers = {},
        on_attach = on_attach,
      })
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",

      "hrsh7th/cmp-vsnip",
      "hrsh7th/vim-vsnip",
    },
    config = function()
      local cmp = require("cmp")

      cmp.setup({
        snippet = {
          -- REQUIRED - you must specify a snippet engine
          expand = function(args)
            vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
            -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
            -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
            -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
          end,
        },
        window = {
          -- completion = cmp.config.window.bordered(),
          -- documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "vsnip" }, -- For vsnip users.
          -- { name = 'luasnip' }, -- For luasnip users.
          -- { name = 'ultisnips' }, -- For ultisnips users.
          -- { name = 'snippy' }, -- For snippy users.
        }, {
          { name = "buffer" },
        }),
      })

      -- Set configuration for specific filetype.
      cmp.setup.filetype("gitcommit", {
        sources = cmp.config.sources({
          { name = "git" }, -- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
        }, {
          { name = "buffer" },
        }),
      })

      -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
    end,
  },
}
