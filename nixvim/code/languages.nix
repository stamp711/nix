# Per-language support: LSP servers, formatters, linters, and preview plugins.
# Treesitter grammars use the nixvim default (all grammars).
{
  flake.nixvimModules.default = { pkgs, ... }: {

    # .fbs: no treesitter parser or LSP exists, so vim syntax for highlighting.
    extraPlugins = [ pkgs.vimPlugins.vim-flatbuffers ];

    # clice: C++ language server, not in nixpkgs — package its prebuilt release.
    extraPackages = [
      (
        let
          version = "0.1.2026072205";
          src =
            {
              x86_64-linux = {
                file = "clice-x64-linux-gnu.tar.gz";
                hash = "sha256-HlWU//05C9PlSKsJMVXCP1SdL/yGEMbTkrJzZcRuk4k=";
              };
              aarch64-linux = {
                file = "clice-arm64-linux-gnu.tar.gz";
                hash = "sha256-ZHFVWk4ZDIzKGDZFlUqnKat3NzZnrtAn1LWSIgKyq7M=";
              };
              aarch64-darwin = {
                file = "clice-arm64-macos-darwin.tar.gz";
                hash = "sha256-6EBpm37/SxMK33RJDzWjl2HlxigkW0Z8u35amwXuN0U=";
              };
            }
            .${pkgs.stdenv.hostPlatform.system};
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = "clice";
          inherit version;
          src = pkgs.fetchurl {
            url = "https://github.com/clice-io/clice/releases/download/v${version}/${src.file}";
            inherit (src) hash;
          };
          nativeBuildInputs = pkgs.lib.optional pkgs.stdenv.isLinux pkgs.autoPatchelfHook;
          buildInputs = pkgs.lib.optional pkgs.stdenv.isLinux pkgs.stdenv.cc.cc.lib;
          # bin/clice finds its clang resource-dir at ../lib/clang relative to itself; keep the tree intact.
          installPhase = ''
            runHook preInstall
            mkdir -p $out
            cp -r bin lib $out/
            runHook postInstall
          '';
          meta.mainProgram = "clice";
        }
      )
    ];

    # clice has no nixpkgs/lspconfig entry, so register it via the native LSP API (nvim 0.11+).
    extraConfigLuaPost = ''
      do
        local caps = require("blink.cmp").get_lsp_capabilities()
        caps.workspace = caps.workspace or {}
        caps.workspace.fileOperations = { didRename = true, willRename = true }
        vim.lsp.config("clice", {
          cmd = { "clice", "serve" },
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
          root_markers = { "compile_commands.json", ".clice", "clice.toml", ".git" },
          capabilities = caps,
        })
        vim.lsp.enable("clice")
      end
    '';

    plugins.lsp.servers = {
      jsonls.enable = true;
      lua_ls.enable = true;
      marksman.enable = true;
      nil_ls.enable = true;
      basedpyright.enable = true;
      protols.enable = true; # protobuf
      taplo.enable = true; # TOML
      tinymist.enable = true; # typst
      zls.enable = true; # Zig
    };

    # neovim + plugin types for lua_ls
    plugins.lazydev = {
      enable = true;
      settings.library = [
        {
          path = "${pkgs.vimPlugins.snacks-nvim}"; # needs absolute path
          words = [ "Snacks" ];
        }
      ];
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
