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

      ## LSP doesn't format
      lua = [ "stylua" ];
      markdown = [ "prettierd" ];
      proto = [ "clang_format" ];
      python = [ "ruff_format" ];

      ## LSP can format, but doesn't range format
      nix = [ "nixfmt" ];
      toml = [ "taplo" ];
      zig = [ "zigfmt" ];

      ## We deliberately don't want LSP's formatter
      c = [ "clang_format" ];
      cpp = [ "clang_format" ]; # we have a custom clang_format wrapper
      json = [ "prettierd" ];
      jsonc = [ "prettier" ];

    };

    # Tailscale .hujson is just jsonc
    filetype.extension.hujson = "jsonc";
    # prettier can't infer .hujson's parser; force the jsonc parser.
    plugins.conform-nvim.settings.formatters.prettier.options.ft_parsers.jsonc = "jsonc";

    plugins.lint.lintersByFt = {
      sh = [ "shellcheck" ];
      nix = [ "statix" ];
      markdown = [ "markdownlint-cli2" ];
    };

  };
}
