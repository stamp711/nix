{
  description = "Zsh with oh-my-zsh, starship prompt, history search, and theme";

  module =
    {
      inputs,
      pkgs,
      config,
      ...
    }:
    let
      nix-colors-lib = inputs.nix-colors.lib.contrib { inherit pkgs; };
    in
    {
      imports = [
        inputs.nix-colors.homeManagerModules.default
      ];

      # Color scheme
      colorScheme = inputs.nix-colors.colorSchemes.dracula;

      # Zsh configuration
      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
        enableVteIntegration = true;
        syntaxHighlighting.enable = true;
        oh-my-zsh = {
          enable = true;
          theme = "robbyrussell";
          plugins = [
            # Productivity
            "command-not-found"
            "encode64"
            "extract"
            "fbterm"
            "history-substring-search"
            "urltools"
            "web-search"
            # Build tools
            "git"
            "gitignore"
            "gnu-utils"
            "kubectl"
            # Distro-related
            "systemd"
            # macOS
            "brew"
            "macos"
            # Misc
            "themes"
          ];
        };
        plugins = [
          {
            name = "zsh-nix-shell";
            src = pkgs.zsh-nix-shell;
            file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
          }
        ];
        initContent = ''
          unset __HM_SESS_VARS_SOURCED # workaround for orbstack shells
          [ -f ~/.config/op/plugins.sh ] && source ~/.config/op/plugins.sh
          # Apply color scheme
          #${nix-colors-lib.shellThemeFromScheme { scheme = config.colorScheme; }}
          # source extra rc in home dir if found
          [ -f ~/.zshrc_extra ] && source ~/.zshrc_extra
        '';
      };

      # History search
      programs.hstr.enable = true;

      # Starship prompt
      programs.starship = {
        enable = true;
        settings = {
          git_metrics.disabled = false;
          kubernetes.disabled = false;
          container.disabled = true;
        };
      };
    };
}
