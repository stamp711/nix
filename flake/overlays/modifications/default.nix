{ inputs, ... }:
{
  flake.overlays.modifications = final: prev: {

    inherit (inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system})
      claude-code
      codex
      opencode
      ;

    # Default clang-format to --fallback-style=none so it no-ops when no
    # .clang-format is present (instead of silently reformatting to LLVM).
    clang-tools = prev.symlinkJoin {
      name = prev.clang-tools.name;
      paths = [ prev.clang-tools ];
      nativeBuildInputs = [ prev.makeWrapper ];
      postBuild = ''
        rm -f $out/bin/clang-format
        makeWrapper ${prev.clang-tools}/bin/clang-format $out/bin/clang-format \
          --add-flags --fallback-style=none
      '';
      inherit (prev.clang-tools) meta;
    };

    # GameScope HDR toggle patch.
    gamescope = prev.gamescope.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./gamescope-nvidia-hdr-toggle-flicker.patch ];
    });

    # Mihomo's fallback proxy-group: when no member passes its health-check,
    # use the LAST member as last resort instead of the first.
    mihomo = prev.mihomo.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace adapter/outboundgroup/fallback.go \
          --replace-fail 'return proxies[0]' 'return proxies[len(proxies)-1]'
      '';
    });

    # Let `attach --config` re-bind keys.
    zellij-unwrapped = prev.zellij-unwrapped.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./zellij-attach-keybinds.patch ];
    });

    vimPlugins = prev.vimPlugins.extend (
      _: super: {

        # neovim Moduls theme
        # modus's util.lua sets the :terminal slots from bg_main/fg_main/*_intense instead of its
        # own spec bg_term_* keys (the extras use those); on light themes that makes highlights black.
        modus-themes-nvim = super.modus-themes-nvim.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace lua/modus-themes/util.lua \
              --replace-fail 'vim.g.terminal_color_0 = colors.bg_main' 'vim.g.terminal_color_0 = colors.bg_term_black' \
              --replace-fail 'vim.g.terminal_color_8 = colors.bg_dim' 'vim.g.terminal_color_8 = colors.bg_term_black_bright' \
              --replace-fail 'vim.g.terminal_color_7 = colors.fg_main' 'vim.g.terminal_color_7 = colors.bg_term_white' \
              --replace-fail 'vim.g.terminal_color_15 = colors.fg_dim' 'vim.g.terminal_color_15 = colors.bg_term_white_bright' \
              --replace-fail 'vim.g.terminal_color_1 = colors.red' 'vim.g.terminal_color_1 = colors.bg_term_red' \
              --replace-fail 'vim.g.terminal_color_9 = colors.red_intense' 'vim.g.terminal_color_9 = colors.bg_term_red_bright' \
              --replace-fail 'vim.g.terminal_color_2 = colors.green' 'vim.g.terminal_color_2 = colors.bg_term_green' \
              --replace-fail 'vim.g.terminal_color_10 = colors.green_intense' 'vim.g.terminal_color_10 = colors.bg_term_green_bright' \
              --replace-fail 'vim.g.terminal_color_3 = colors.yellow' 'vim.g.terminal_color_3 = colors.bg_term_yellow' \
              --replace-fail 'vim.g.terminal_color_11 = colors.yellow_intense' 'vim.g.terminal_color_11 = colors.bg_term_yellow_bright' \
              --replace-fail 'vim.g.terminal_color_4 = colors.blue' 'vim.g.terminal_color_4 = colors.bg_term_blue' \
              --replace-fail 'vim.g.terminal_color_12 = colors.blue_intense' 'vim.g.terminal_color_12 = colors.bg_term_blue_bright' \
              --replace-fail 'vim.g.terminal_color_5 = colors.magenta' 'vim.g.terminal_color_5 = colors.bg_term_magenta' \
              --replace-fail 'vim.g.terminal_color_13 = colors.magenta_intense' 'vim.g.terminal_color_13 = colors.bg_term_magenta_bright' \
              --replace-fail 'vim.g.terminal_color_6 = colors.cyan' 'vim.g.terminal_color_6 = colors.bg_term_cyan' \
              --replace-fail 'vim.g.terminal_color_14 = colors.cyan_intense' 'vim.g.terminal_color_14 = colors.bg_term_cyan_bright'
          '';
        });

        # closingLine foldtext option.
        nvim-origami = super.nvim-origami.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./origami-closingline.patch ];
        });

      }
    );

  };
}
