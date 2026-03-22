# Lazy-load zsh plugins and init using zsh-defer
{
  flake.homeModules.my =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkOption types;

      cfg = config.my.zsh-defer;

      pluginsDir = "${config.xdg.configHome}/zsh/deferred-plugins";

      # Compile .zsh files to .zwc bytecode at build time
      compilePlugin =
        src:
        pkgs.runCommand "${baseNameOf (toString src)}-zwc" { nativeBuildInputs = [ pkgs.zsh ]; } ''
          cp -rL ${src} $out
          chmod -R u+w $out
          find $out -name '*.zsh' -exec zsh -c 'zcompile {}' \;
        '';

      # Re-bind autosuggestion ZLE widgets.
      # Must run before rebindHighlight so the highlighter ends up as the outermost wrapper.
      rebindAutosuggest = ''
        (( $+functions[_zsh_autosuggest_bind_widgets] )) && _zsh_autosuggest_bind_widgets
      '';

      # Re-bind highlight ZLE widgets.
      # Must run after rebindAutosuggest to be the outermost wrapper, ensuring all keystrokes trigger highlighting.
      rebindHighlight = ''
        (( $+functions[_zsh_highlight_bind_widgets] )) && _zsh_highlight_bind_widgets
      '';

      # Fetch a suggestion for the current buffer after deferred loading.
      refreshAutosuggest = ''
        (( $+functions[_zsh_autosuggest_fetch] )) && _zsh_autosuggest_fetch
      '';

      # Re-highlight current buffer after deferred syntax highlighting loads.
      # Registers and invokes a ZLE widget for $region_highlight access.
      refreshHighlight = ''
        zsh-defer-rehighlight_() {
          _ZSH_HIGHLIGHT_PRIOR_BUFFER=
          (( $+functions[_zsh_highlight] )) && _zsh_highlight
        }
        zle -N zsh-defer-rehighlight_
        zle zsh-defer-rehighlight_
      '';

      # Flush display changes to screen.
      redraw = ''
        zle -R
      '';

      # Re-bind all widgets and refresh display in one pass after all plugins
      # have loaded. Avoids multiple ZLE redraws (flicker).
      # Guards skip inactive plugins.
      postPluginRefresh =
        rebindAutosuggest + rebindHighlight + refreshAutosuggest + refreshHighlight + redraw;

      pluginModule = types.submodule (
        { config, ... }:
        {
          options = {
            name = mkOption {
              type = types.str;
              description = "Plugin name (used for the deferred-plugins directory name).";
            };
            src = mkOption {
              type = types.path;
              description = ''
                Path to the plugin folder.

                Will be added to {env}`fpath` and {env}`PATH`.
              '';
            };
            file = mkOption {
              type = types.str;
              description = ''
                The plugin script to source.
                Required if the script name does not match {file}`name.plugin.zsh`
                using the plugin {option}`name` from the plugin {option}`src`.
              '';
            };
            completions = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Paths of additional functions to add to {env}`fpath`.";
            };
            order = mkOption {
              type = types.int;
              default = 1000;
              description = "Order for deferred loading (lower = earlier).";
            };
          };

          config.file = lib.mkDefault "${config.name}.plugin.zsh";
        }
      );

      entryModule = types.submodule {
        options = {
          order = mkOption {
            type = types.int;
            default = 1000;
            description = "Order for deferred loading (lower = earlier).";
          };
          content = mkOption {
            type = types.lines;
            description = "Shell code to run via zsh-defer.";
          };
        };
      };

    in
    {
      options.my.zsh-defer = {
        enable = lib.mkEnableOption "zsh-defer lazy loading";

        lib.compilePlugin = mkOption {
          type = types.functionTo types.package;
          readOnly = true;
          default = compilePlugin;
          description = "Compile .zsh files in a plugin source to .zwc bytecode at build time.";
        };

        initContent = mkOption {
          type = types.listOf entryModule;
          default = [ ];
          example = lib.literalExpression ''
            [
              {
                order = 800;
                content = "autoload -U compinit && compinit -C -u";
              }
              {
                order = 1000;
                content = '''eval "$(mise activate zsh)"''';
              }
            ]
          '';
          description = ''
            Shell init entries to run via zsh-defer. Each entry has an order
            and content. Entries are sorted by order and interleaved with
            deferred plugins.

            Order conventions (matching programs.zsh.initContent):
            - 500 (mkBefore): Early initialization
            - 600: Syntax highlighting (enableSyntaxHighlighting / enableFastSyntaxHighlighting)
            - 700: Autosuggestions (enableAutosuggestion)
            - 800: Completion system (compinit, via enableCompletion)
            - 1000 (default): General configuration (tool inits, plugins)
            - 1200: Re-bind widgets, rehighlight, refetch
            - 1500 (mkAfter): Last to run
          '';
        };

        plugins = mkOption {
          type = types.listOf pluginModule;
          default = [ ];
          example = lib.literalExpression ''
            [
              {
                name = "you-should-use";
                src = "''${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use";
              }
              {
                name = "fast-syntax-highlighting";
                src = "''${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
                order = 1500; # should be last
              }
            ]
          '';
          description = "Plugins to load via zsh-defer.";
        };

        enableSyntaxHighlighting = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Enable deferred zsh-syntax-highlighting. When enabled,
            {option}`programs.zsh.syntaxHighlighting.enable` is disabled and the
            plugin is loaded via zsh-defer at order 600 instead.

            Configure highlighters, patterns and styles via
            {option}`programs.zsh.syntaxHighlighting`.
          '';
        };

        enableFastSyntaxHighlighting = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Enable deferred fast-syntax-highlighting. When enabled,
            the plugin is loaded via zsh-defer at order 600.

            Configure via `fast-theme` command or theme files.
          '';
        };

        enableAutosuggestion = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Enable deferred zsh autosuggestions. When enabled,
            {option}`programs.zsh.autosuggestion.enable` is disabled and the
            plugin is loaded via zsh-defer at order 700 instead.

            Configure strategy and highlight via {option}`programs.zsh.autosuggestion`.
          '';
        };

        enableCompletion = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Enable deferred completion system. When enabled, compinit runs
            via zsh-defer instead of synchronously, and
            {option}`programs.zsh.enableCompletion` is disabled.
          '';
        };

        completionInit = mkOption {
          type = types.lines;
          default = "autoload -U compinit && compinit";
          description = ''
            Initialization commands for the deferred completion system.
            Only used when {option}`enableCompletion` is true.
            Runs at order 800 in the deferred queue.
          '';
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          # Core: zsh-defer plugin, symlinks, fpath/PATH, deferred queue
          {
            programs.zsh.plugins = [
              {
                name = "zsh-defer";
                src = "${pkgs.zsh-defer}/share/zsh-defer";
              }
            ];

            home.file = lib.mergeAttrsList (
              map (plugin: {
                "${pluginsDir}/${plugin.name}".source = compilePlugin plugin.src;
              }) cfg.plugins
            );

            programs.zsh.initContent =
              let
                pluginEntries = map (plugin: {
                  inherit (plugin) order;
                  content = ''[[ -f "${pluginsDir}/${plugin.name}/${plugin.file}" ]] && source "${pluginsDir}/${plugin.name}/${plugin.file}"'';
                }) cfg.plugins;

                allEntries = lib.sort (a: b: a.order < b.order) (cfg.initContent ++ pluginEntries);
                # -a +1 +2: disable all actions, only suppress stdout and stderr
                # -t 0.00001: yield to ZLE between items (KEYS_QUEUED_COUNT broken on macOS)
                # Final item with defaults triggers one round of hooks + redraw
                wrapped =
                  map (e: "zsh-defer -a +1 +2 -t 0.00001 -c ${lib.escapeShellArg e.content}") allEntries
                  ++ [
                    "zsh-defer -c :"
                  ];

                pluginNames = map (plugin: plugin.name) cfg.plugins;
                completionPaths = lib.flatten (
                  map (plugin: map (completion: "${plugin.name}/${completion}") plugin.completions) cfg.plugins
                );
              in
              lib.mkMerge [
                # Add deferred plugin/completion directories to PATH and fpath
                (lib.mkOrder 560 ''
                  ${lib.hm.zsh.define "deferred_plugin_dirs" pluginNames}
                  # Add plugin paths
                  for plugin_dir in "''${deferred_plugin_dirs[@]}"; do
                    path+="${pluginsDir}/$plugin_dir"
                    fpath+="${pluginsDir}/$plugin_dir"
                  done
                  unset plugin_dir deferred_plugin_dirs
                  ${lib.optionalString (completionPaths != [ ]) ''
                    # Add completion paths
                    ${lib.hm.zsh.define "deferred_completion_paths" completionPaths}
                    for completion_path in "''${deferred_completion_paths[@]}"; do
                      fpath+="${pluginsDir}/$completion_path"
                    done
                    unset completion_path deferred_completion_paths
                  ''}
                '')

                # Inject deferred commands after sync plugins (900) and default initContent (1000) in HM initContent
                (lib.mkOrder 1100 (lib.concatStringsSep "\n" wrapped))
              ];
          }

          # Mutual exclusion: syntax highlighting plugins
          {
            assertions = [
              {
                assertion = !(cfg.enableSyntaxHighlighting && cfg.enableFastSyntaxHighlighting);
                message = "my.zsh-defer.enableSyntaxHighlighting and my.zsh-defer.enableFastSyntaxHighlighting are mutually exclusive.";
              }
            ];
          }

          # 600: Deferred zsh-syntax-highlighting
          (lib.mkIf cfg.enableSyntaxHighlighting (
            let
              sh = config.programs.zsh.syntaxHighlighting;
            in
            {
              programs.zsh.syntaxHighlighting.enable = lib.mkOverride 900 false; # Disable HM option
              programs.zsh.syntaxHighlighting.highlighters = lib.mkDefault [ "main" ]; # Replicate logic from HM
              warnings = lib.optional config.programs.zsh.syntaxHighlighting.enable ''
                Both my.zsh-defer.enableSyntaxHighlighting and programs.zsh.syntaxHighlighting.enable are enabled.
                Set programs.zsh.syntaxHighlighting.enable = false to avoid loading syntax highlighting twice.
              '';
              my.zsh-defer.plugins = [
                {
                  name = "zsh-syntax-highlighting";
                  src = "${sh.package}/share/zsh-syntax-highlighting";
                  file = "zsh-syntax-highlighting.zsh";
                  order = 601;
                }
              ];
              my.zsh-defer.initContent =
                lib.optional (sh.highlighters != [ ]) {
                  order = 600;
                  content = "ZSH_HIGHLIGHT_HIGHLIGHTERS=(${lib.concatStringsSep " " (map lib.escapeShellArg sh.highlighters)})";
                }
                ++ lib.optional (sh.styles != { }) {
                  order = 600;
                  content = lib.concatStringsSep "\n" (
                    lib.mapAttrsToList (
                      name: value: "ZSH_HIGHLIGHT_STYLES[${lib.escapeShellArg name}]=${lib.escapeShellArg value}"
                    ) sh.styles
                  );
                }
                ++ lib.optional (sh.patterns != { }) {
                  order = 600;
                  content = lib.concatStringsSep "\n" (
                    lib.mapAttrsToList (
                      name: value: "ZSH_HIGHLIGHT_PATTERNS+=(${lib.escapeShellArg name} ${lib.escapeShellArg value})"
                    ) sh.patterns
                  );
                };
            }
          ))

          # 600: Deferred fast-syntax-highlighting
          # Loaded early (order 600) for minimal delay, then ZLE widgets are re-bound after all other plugins (order 1200).
          (lib.mkIf cfg.enableFastSyntaxHighlighting {
            programs.zsh.syntaxHighlighting.enable = lib.mkOverride 900 false; # Disable HM option
            warnings = lib.optional config.programs.zsh.syntaxHighlighting.enable ''
              Both my.zsh-defer.enableFastSyntaxHighlighting and programs.zsh.syntaxHighlighting.enable are enabled.
              Set programs.zsh.syntaxHighlighting.enable = false to avoid loading syntax highlighting twice.
            '';
            my.zsh-defer.plugins = [
              {
                name = "fast-syntax-highlighting";
                src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
                file = "fast-syntax-highlighting.plugin.zsh";
                order = 600;
              }
            ];
          })

          # 700: Deferred autosuggestions
          (lib.mkIf cfg.enableAutosuggestion (
            let
              as = config.programs.zsh.autosuggestion;
            in
            {
              programs.zsh.autosuggestion.enable = lib.mkOverride 900 false; # Disable HM option
              warnings = lib.optional config.programs.zsh.autosuggestion.enable ''
                Both my.zsh-defer.enableAutosuggestion and programs.zsh.autosuggestion.enable are enabled.
                Set programs.zsh.autosuggestion.enable = false to avoid loading autosuggestions twice.
              '';
              my.zsh-defer.plugins = [
                {
                  name = "zsh-autosuggestions";
                  src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
                  file = "zsh-autosuggestions.zsh";
                  order = 701;
                }
              ];
              my.zsh-defer.initContent = [
                # Skip per-precmd rebind; we rebind explicitly at 702 and 1200.
                {
                  order = 700;
                  content = "ZSH_AUTOSUGGEST_MANUAL_REBIND=1";
                }
              ]
              ++ lib.optional (as.strategy != [ ]) {
                order = 700;
                content = "ZSH_AUTOSUGGEST_STRATEGY=(${lib.concatStringsSep " " as.strategy})";
              }
              ++ lib.optional (as.highlight != null) {
                order = 700;
                content = ''ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="${as.highlight}"'';
              }
              ++ [
                # Bind widgets after load. Autosuggestions defers binding to a
                # precmd hook, which will not fire between first and second prompt.
                {
                  order = 702;
                  content = rebindAutosuggest;
                }
              ];
            }
          ))

          # 800: Deferred completion system
          (lib.mkIf cfg.enableCompletion {
            programs.zsh.enableCompletion = lib.mkOverride 900 false;
            home.packages = [ (lib.lowPrio pkgs.nix-zsh-completions) ];
            warnings = lib.optional config.programs.zsh.enableCompletion ''
              Both my.zsh-defer.enableCompletion and programs.zsh.enableCompletion are enabled.
              This will run compinit twice (sync + deferred).
              Set programs.zsh.enableCompletion = false to avoid this.
            '';
            my.zsh-defer.initContent = [
              {
                order = 800;
                content = cfg.completionInit;
              }
            ];
          })

          # 750:  Initial display refresh after syntax highlighting + autosuggestions are loaded.
          #       No rebinds needed, highlighters bind at source time (600/601), autosuggestions binds at 702.
          # 1200: Re-bind all widgets for plugins loaded after 750 (e.g. user plugins at 1000), then refresh.
          #       rebindAutosuggest before rebindHighlight so the highlighter is the outermost ZLE wrapper.
          (lib.mkIf
            (cfg.enableAutosuggestion || cfg.enableSyntaxHighlighting || cfg.enableFastSyntaxHighlighting)
            {
              my.zsh-defer.initContent = [
                {
                  order = 750;
                  content = refreshAutosuggest + refreshHighlight + redraw;
                }
                {
                  order = 1200;
                  content = postPluginRefresh;
                }
              ];
            }
          )

        ]
      );
    };
}
