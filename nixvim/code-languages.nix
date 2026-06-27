{
  flake.nixvimModules.default =
    # Per-language support: LSP servers, treesitter grammars, and formatters.
    { config, ... }:
    {
      plugins.lsp.servers = {
        clangd.enable = true;
        jsonls.enable = true;
        marksman.enable = true;
        nil_ls.enable = true;
        basedpyright.enable = true;
        taplo.enable = true;
        zls.enable = true;
      };

      # Rust goes through rustaceanvim (pulls rust-analyzer); don't also enable
      # lsp.servers.rust_analyzer.
      plugins.rustaceanvim.enable = true;

      plugins.treesitter.grammarPackages = with config.plugins.treesitter.package.builtGrammars; [
        bash
        c
        cpp
        diff
        json
        markdown
        markdown_inline
        nix
        python
        regex
        rust
        toml
        yaml
        zig
      ];

      plugins.conform-nvim.settings.formatters_by_ft = {
        c = [ "clang_format" ];
        cpp = [ "clang_format" ];
        json = [ "prettierd" ];
        markdown = [ "prettierd" ];
        nix = [ "nixfmt" ];
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
