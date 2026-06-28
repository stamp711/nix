{
  flake.nixvimModules.default =
    # Folds: nvim-origami — LSP folds (treesitter/indent fallback), foldtext (line+diag+git), h/l/^/$ fold keys.
    { pkgs, ... }:
    {
      extraPlugins = [ pkgs.vimPlugins.nvim-origami ];

      opts = {
        foldlevel = 99;
        foldlevelstart = 99;
        fillchars = {
          fold = " ";
          foldsep = " ";
          foldopen = "";
          foldclose = "";
        };
      };

      extraConfigLuaPost = ''
        require("which-key").add({ { "z", group = "fold" } })
        -- nr2char(0xF0616) = nf-md-arrow_expand
        require("origami").setup({
          foldtext = {
            lineCount = { template = vim.fn.nr2char(0xF0616) .. " %d" },
            closingLine = { enabled = true }, -- patched-in option (flake/overlays/origami-closingline.patch)
          },
        })
      '';
    };
}
