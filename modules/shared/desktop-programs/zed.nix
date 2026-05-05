{
  flake.darwinModules.desktop-programs = {
    homebrew.casks = [ "zed" ];
  };

  flake.homeModules.desktop-programs =
    { pkgs, ... }:
    {
      programs.zed-editor = {
        enable = true;
        package = if pkgs.stdenv.isDarwin then null else pkgs.zed-editor;
        installRemoteServer = true;
        extensions = [
          "wakatime"
          "nix"
          "xy-zed"
          "cyan-light-theme"
          "catppuccin"
          "kanagawa-themes"
          "modus-themes"
        ];
        userSettings = {
          # Essentials
          telemetry.diagnostics = false;
          telemetry.metrics = false;
          cursor_blink = false;
          session.trust_all_worktrees = true;
          vim_mode = true;
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
          # LLM
          edit_predictions.mode = "subtle";
          agent = {
            expand_terminal_card = false;
            enable_feedback = false;
            single_file_review = true;
            play_sound_when_agent_done = "when_hidden";
          };
          # Language formatters
          languages = {
            YAML.formatter.external = {
              command = "prettier";
              arguments = [
                "--stdin-filepath"
                "{buffer_path}"
              ];
            };
            JSON.formatter.external = {
              command = "prettier";
              arguments = [
                "--stdin-filepath"
                "{buffer_path}"
              ];
            };
          };
          "document_symbols" = "on";
        };
      };
    };
}
