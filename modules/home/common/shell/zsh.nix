{
  description = "Zsh with oh-my-zsh, starship prompt, and modern history";

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
        history = {
          size = 100000;
          save = 100000;
          expireDuplicatesFirst = true;
          extended = true;
        };
        oh-my-zsh = {
          enable = true;
          theme = "";
          plugins = [
            "aliases"
            # Productivity
            "command-not-found"
            "encode64"
            "extract"
            "fbterm"
            "urltools"
            "web-search"
            # Build tools
            "git"
            "gitignore"
            "gnu-utils"
            "jj"
            "kubectl"
            # Distro-related
            "systemd"
            # macOS
            "brew"
            "macos"
          ];
        };
        plugins = [
          {
            name = "zsh-nix-shell";
            src = pkgs.zsh-nix-shell;
            file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
          }
          {
            name = "you-should-use";
            src = pkgs.zsh-you-should-use;
            file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
          }
        ];
        initContent = ''
          export YSU_MESSAGE_FORMAT="💡 $(tput setab 22)$(tput setaf 231) %alias $(tput sgr0)"
          unset __HM_SESS_VARS_SOURCED # workaround for orbstack shells
          [ -f ~/.config/op/plugins.sh ] && source ~/.config/op/plugins.sh
          # Apply color scheme
          #${nix-colors-lib.shellThemeFromScheme { scheme = config.colorScheme; }}
          # source extra rc in home dir if found
          [ -f ~/.zshrc_extra ] && source ~/.zshrc_extra
        '';
      };

      programs.fzf.enable = true;

      programs.atuin = {
        enable = true;
        flags = [ "--disable-up-arrow" ];
        settings = {
          style = "auto";
          invert = true;
          inline_height = 20;
        };
      };

      # Starship prompt
      home.packages = [
        inputs.jj-starship.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
      programs.starship = {
        enable = true;
        settings = {
          # Replaced by jj-starship
          git_branch.disabled = true;
          git_commit.disabled = true;
          git_status.disabled = true;
          # git_metrics.disabled = false;

          kubernetes.disabled = false;
          container.disabled = true;
          custom.jj = {
            when = "jj-starship detect";
            shell = "jj-starship";
            format = "$output ";
          };
        };
      };
    };
}
