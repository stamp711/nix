# Per-language support: LSP servers, formatters, and linters.
# Treesitter grammars use the nixvim default (all grammars).
{
  flake.nixvimModules.default = { pkgs, ... }: {

    # .fbs: no treesitter parser or LSP exists, so vim syntax for highlighting.
    extraPlugins = [ pkgs.vimPlugins.vim-flatbuffers ];

    plugins.lsp.servers = {
      clangd.enable = true;
      jsonls.enable = true;
      marksman.enable = true;
      nil_ls.enable = true;
      basedpyright.enable = true;
      protols.enable = true;
      taplo.enable = true;
      zls.enable = true;
    };

    # Rust goes through rustaceanvim (pulls rust-analyzer); don't also enable
    # lsp.servers.rust_analyzer.
    plugins.rustaceanvim.enable = true;

    plugins.conform-nvim.settings.formatters_by_ft = {
      c = [ "clang_format" ];
      cpp = [ "clang_format" ];
      json = [ "prettierd" ];
      lua = [ "stylua" ];
      markdown = [ "prettierd" ];
      nix = [ "nixfmt" ];
      proto = [ "clang_format" ];
      python = [ "ruff_format" ];
      toml = [ "taplo" ];
      zig = [ "zigfmt" ];
    };

    plugins.lint.lintersByFt = {
      sh = [ "shellcheck" ];
      nix = [ "statix" ];
      markdown = [ "markdownlint-cli2" ];
    };

  };
}
