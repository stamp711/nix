return {
  { "williamboman/mason.nvim", cmd = "Mason", config = true },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason.nvim", "williamboman/mason-lspconfig.nvim", "simrat39/rust-tools.nvim" },
    -- TODO: write the setup function which takes opts merged from different files (for different languages)
    -- refer: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/extras/lang/typescript.lua
    opts = {},
    config = function(_, opts)
      local mlsp = require("mason-lspconfig");
      mlsp.setup { automatic_installation = true };
      mlsp.setup_handlers {
        function(server_name) -- default handler (optional)
          require("lspconfig")[server_name].setup {}
        end,
        ["rust_analyzer"] = function() -- override for `rust_analyzer`
          require("rust-tools").setup {}
        end
      }
    end
  },
}
