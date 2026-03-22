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

      # Re-highlight current buffer after deferred syntax highlighting loads.
      # Registers and invokes a ZLE widget for $region_highlight access.
      rehighlightContent = ''
        zsh-defer-rehighlight_() {
          _ZSH_HIGHLIGHT_PRIOR_BUFFER=
          (( $+functions[_zsh_highlight] )) && _zsh_highlight
        }
        zle -N zsh-defer-rehighlight_
        zle zsh-defer-rehighlight_
      '';

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
            Runs at order 570 in the deferred queue (matching HM's completionInit order).
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

        enableSyntaxHighlighting = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Enable deferred zsh-syntax-highlighting. When enabled,
            {option}`programs.zsh.syntaxHighlighting.enable` is disabled and the
            plugin is loaded via zsh-defer at order 1200 instead.

            Configure highlighters, patterns and styles via
            {option}`programs.zsh.syntaxHighlighting`.
          '';
        };

        enableFastSyntaxHighlighting = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Enable deferred fast-syntax-highlighting. When enabled,
            the plugin is loaded via zsh-defer at order 1200.

            Configure via `fast-theme` command or theme files.
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

        initContent = mkOption {
          type = types.listOf entryModule;
          default = [ ];
          example = lib.literalExpression ''
            [
              {
                order = 570;
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
            - 550: Before completion initialization
            - 570: Completion system (compinit, via enableCompletion)
            - 1000 (default): General configuration (tool inits, plugins)
            - 1500 (mkAfter): Last to run (syntax highlighting)
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
                # -a +1 +2: disable all actions except stdout/stderr suppression
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
                (lib.mkOrder 560 ''
                  # Add deferred plugin directories to PATH and fpath
                  ${lib.hm.zsh.define "deferred_plugin_dirs" pluginNames}
                  for plugin_dir in "''${deferred_plugin_dirs[@]}"; do
                    path+="${pluginsDir}/$plugin_dir"
                    fpath+="${pluginsDir}/$plugin_dir"
                  done
                  unset plugin_dir deferred_plugin_dirs
                  ${lib.optionalString (completionPaths != [ ]) ''
                    # Add completion paths to fpath
                    ${lib.hm.zsh.define "deferred_completion_paths" completionPaths}
                    for completion_path in "''${deferred_completion_paths[@]}"; do
                      fpath+="${pluginsDir}/$completion_path"
                    done
                    unset completion_path deferred_completion_paths
                  ''}
                '')

                # Inject deferred commands after sync plugins (900) and default initContent (1000)
                (lib.mkOrder 1100 (lib.concatStringsSep "\n" wrapped))
              ];
          }

          # Deferred completion system
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
                order = 570;
                content = cfg.completionInit;
              }
            ];
          })

          # Deferred autosuggestions
          (lib.mkIf cfg.enableAutosuggestion (
            let
              as = config.programs.zsh.autosuggestion;
            in
            {
              programs.zsh.autosuggestion.enable = lib.mkOverride 900 false;
              warnings = lib.optional config.programs.zsh.autosuggestion.enable ''
                Both my.zsh-defer.enableAutosuggestion and programs.zsh.autosuggestion.enable are enabled.
                Set programs.zsh.autosuggestion.enable = false to avoid loading autosuggestions twice.
              '';
              my.zsh-defer.plugins = [
                {
                  name = "zsh-autosuggestions";
                  src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
                  file = "zsh-autosuggestions.zsh";
                  order = 700;
                }
              ];
              my.zsh-defer.initContent =
                lib.optional (as.strategy != [ ]) {
                  order = 701; # after plugin source at 700, matching HM
                  content = "ZSH_AUTOSUGGEST_STRATEGY=(${lib.concatStringsSep " " as.strategy})";
                }
                ++ lib.optional (as.highlight != null) {
                  order = 701; # after plugin source at 700, matching HM
                  content = ''ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="${as.highlight}"'';
                };
            }
          ))

          # Mutual exclusion: syntax highlighting plugins
          {
            assertions = [
              {
                assertion = !(cfg.enableSyntaxHighlighting && cfg.enableFastSyntaxHighlighting);
                message = "my.zsh-defer.enableSyntaxHighlighting and my.zsh-defer.enableFastSyntaxHighlighting are mutually exclusive.";
              }
            ];
          }

          # Deferred zsh-syntax-highlighting
          (lib.mkIf cfg.enableSyntaxHighlighting (
            let
              sh = config.programs.zsh.syntaxHighlighting;
            in
            {
              programs.zsh.syntaxHighlighting.enable = lib.mkOverride 900 false;
              programs.zsh.syntaxHighlighting.highlighters = lib.mkDefault [ "main" ];
              warnings = lib.optional config.programs.zsh.syntaxHighlighting.enable ''
                Both my.zsh-defer.enableSyntaxHighlighting and programs.zsh.syntaxHighlighting.enable are enabled.
                Set programs.zsh.syntaxHighlighting.enable = false to avoid loading syntax highlighting twice.
              '';
              my.zsh-defer.plugins = [
                {
                  name = "zsh-syntax-highlighting";
                  src = "${sh.package}/share/zsh-syntax-highlighting";
                  file = "zsh-syntax-highlighting.zsh";
                  order = 1200;
                }
              ];
              my.zsh-defer.initContent =
                lib.optional (sh.highlighters != [ ]) {
                  order = 1201; # after plugin source at 1200, matching HM convention
                  content = "ZSH_HIGHLIGHT_HIGHLIGHTERS=(${lib.concatStringsSep " " (map lib.escapeShellArg sh.highlighters)})";
                }
                ++ lib.optional (sh.styles != { }) {
                  order = 1201;
                  content = lib.concatStringsSep "\n" (
                    lib.mapAttrsToList (
                      name: value: "ZSH_HIGHLIGHT_STYLES[${lib.escapeShellArg name}]=${lib.escapeShellArg value}"
                    ) sh.styles
                  );
                }
                ++ lib.optional (sh.patterns != { }) {
                  order = 1201;
                  content = lib.concatStringsSep "\n" (
                    lib.mapAttrsToList (
                      name: value: "ZSH_HIGHLIGHT_PATTERNS+=(${lib.escapeShellArg name} ${lib.escapeShellArg value})"
                    ) sh.patterns
                  );
                }
                ++ [
                  # Re-highlight current buffer after loading.
                  {
                    order = 1202;
                    content = rehighlightContent;
                  }
                ];
            }
          ))

          # Deferred fast-syntax-highlighting
          (lib.mkIf cfg.enableFastSyntaxHighlighting {
            my.zsh-defer.plugins = [
              {
                name = "fast-syntax-highlighting";
                src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
                file = "fast-syntax-highlighting.plugin.zsh";
                order = 1200;
              }
            ];
            my.zsh-defer.initContent = [
              # Re-highlight current buffer after loading.
              {
                order = 1202;
                content = rehighlightContent;
              }
            ];
          })
        ]
      );
    };
}
