return {
  { "williamboman/mason.nvim",           cmd = "Mason",                            config = true },
  { "williamboman/mason-lspconfig.nvim", dependencies = "williamboman/mason.nvim", config = true },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    -- TODO: write the setup function which takes opts merged from different files (for different languages)
    opts = {},
    config = function(_, opts)
      local mlsp = require("mason-lspconfig");
      mlsp.setup();
      mlsp.setup_handlers {
        -- The first entry (without a key) will be the default handler
        -- and will be called for each installed server that doesn't have
        -- a dedicated handler.
        function(server_name) -- default handler (optional)
          require("lspconfig")[server_name].setup {}
        end,
        -- Next, you can provide a dedicated handler for specific servers.
        -- For example, a handler override for the `rust_analyzer`:
        ["rust_analyzer"] = function()
          require("rust-tools").setup {}
        end
      }
    end
  },
}
