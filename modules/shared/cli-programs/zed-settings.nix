{
  flake.homeModules.cli-programs =
    { lib, ... }:
    {
      programs.zed-editor = {
        enable = true;
        package = lib.mkDefault null; # this is the headless profile
        installRemoteServer = true;

        extensions = [
          "wakatime"
          "nix"
          "cyan-light-theme"
          "catppuccin"
          "kanagawa-themes"
          "modus-themes"
        ];

        mutableUserKeymaps = false;
        userKeymaps = [
          {
            bindings."ctrl-\\" = "workspace::NewCenterTerminal";
          }
          {
            bindings."alt-o" = "editor::SwitchSourceHeader";
          }
          {
            context = "vim_mode == normal || vim_mode == visual";
            bindings."s" = "vim::PushSneak";
            bindings."shift-s" = "vim::PushSneakBackward";
          }
        ];

        mutableUserSettings = false;
        userSettings = {
          # Essentials
          telemetry.diagnostics = false;
          telemetry.metrics = false;
          cursor_blink = false;
          session.trust_all_worktrees = true;
          vim_mode = true;

          # Layout
          outline_panel.dock = "left";
          collaboration_panel.dock = "left";
          git_panel.dock = "left";
          project_panel.dock = "left";

          # Appearance
          ui_font_family = "Monaco Nerd Font";
          ui_font_size = 14;
          buffer_font_family = "Monaco Nerd Font";
          buffer_font_size = 13;
          theme = {
            mode = "system";
            light = "Modus Operandi Tinted";
            dark = "Kanagawa Dragon - No Italics";
          };
          tabs.git_status = true;
          relative_line_numbers = "enabled";

          # Behaviour
          format_on_save = "on";
          terminal.copy_on_select = true;

          # LLM
          edit_predictions = {
            provider = "copilot";
            mode = "subtle";
          };
          agent = {
            dock = "right";
            expand_terminal_card = false;
            enable_feedback = false;
            single_file_review = true;
            play_sound_when_agent_done = "when_hidden";
          };
          agent_servers = {
            github-copilot-cli.type = "registry";
            claude-acp.type = "registry";
          };

          # Languages
          languages =
            let
              prettierFormatter.external = {
                command = "prettier";
                arguments = [
                  "--stdin-filepath"
                  "{buffer_path}"
                ];
              };
            in
            {
              Nix = {
                language_servers = [
                  "nixd"
                  "nil"
                ];
                formatter.external.command = "nixfmt";
              };

              CMake.formatter.external = {
                command = "gersemi";
                arguments = [ "-" ];
              };

              Python.formatter.language_server.name = "ruff";
              JSON.formatter = prettierFormatter;
              YAML.formatter = prettierFormatter;
            };

          lsp.clangd = {
            "binary" = {
              "arguments" = [
                "--background-index"
                "--clang-tidy"
                "--completion-style=detailed"
                "--function-arg-placeholders=0"
                "--all-scopes-completion"
              ];
            };
          };

          code_lens = "on";
          document_symbols = "on";
          diagnostics.inline.enabled = true;
          inlay_hints.toggle_on_modifiers_press.control = true;
          inlay_hints.show_background = true;

          # SSH servers
          ssh_connections = [
            {
              host = "NUC.home";
              args = [ "-A" ];
            }
          ];
        };
      };
    };
}
