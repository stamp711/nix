# Per-language support: LSP servers, formatters, linters, and preview plugins.
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
      protols.enable = true; # protobuf
      taplo.enable = true; # TOML
      tinymist.enable = true; # typst
      zls.enable = true; # Zig
    };

    # Rust goes through rustaceanvim (pulls rust-analyzer); don't also enable
    # lsp.servers.rust_analyzer.
    plugins.rustaceanvim.enable = true;

    # :TypstPreview
    plugins.typst-preview.enable = true;

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
      # changed-lines save formats by range; tinymist has no rangeFormatting
      typst = [ "typstyle" ];
      zig = [ "zigfmt" ];
    };

    plugins.lint.lintersByFt = {
      sh = [ "shellcheck" ];
      nix = [ "statix" ];
      markdown = [ "markdownlint-cli2" ];
    };

  };
}
