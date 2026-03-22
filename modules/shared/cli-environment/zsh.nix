# Zsh with starship prompt, completion, and keybindings
{ self, inputs, ... }:
{
  flake.nixosModules.cli-environment =
    { pkgs, ... }:
    {
      users.defaultUserShell = pkgs.zsh;
      programs.zsh.enable = true;
      # Handled by user zsh config
      programs.zsh.enableCompletion = false;
      programs.zsh.enableBashCompletion = false;
      programs.zsh.promptInit = "";
    };

  flake.darwinModules.cli-environment = {
    # Handled by user zsh config
    programs.zsh.enableCompletion = false;
    programs.zsh.enableBashCompletion = false;
    programs.zsh.promptInit = "";
  };

  flake.homeModules.cli-environment =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      compile = config.my.zsh-defer.lib.compilePlugin;
      omz = compile "${pkgs.oh-my-zsh}/share/oh-my-zsh";
      omzLib = name: {
        name = "omz-lib-${name}";
        src = omz;
        file = "lib/${name}.zsh";
      };
      omzPlugin = name: {
        name = "omz-plugin-${name}";
        src = omz;
        file = "plugins/${name}/${name}.plugin.zsh";
      };
      fromPkg = pkg: file: {
        name = pkg.pname or pkg.name;
        src = compile pkg;
        inherit file;
      };
    in
    {
      programs.bash = {
        enable = true;
        enableVteIntegration = true;
      };

      # Zsh configuration
      programs.zsh = {
        enable = true;
        enableVteIntegration = true;
        history = {
          size = 100000;
          save = 100000;
          expireDuplicatesFirst = true;
          extended = true;
        };
        plugins = [
          # OMZ libs: must be sync for terminal/input behavior
          (omzLib "key-bindings")
          (omzLib "functions") # needed by termsupport (omz_urlencode)
          (omzLib "clipboard")
          (omzLib "termsupport")
        ];

        initContent = lib.mkMerge [
          # - 500 (mkBefore): Early initialization (replaces initExtraFirst)
          (lib.mkBefore ''
            # zsh startup profiling: run `zsh-prof` to see what's slow
            if [[ -n "$ZPROF" ]]; then
              zmodload zsh/zprof
            fi

            # Powerlevel10k instant prompt (must be near top of zshrc)
            if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
              source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
            fi

            # Load p10k theme
            source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

            # Load p10k config
            source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/config/p10k-pure.zsh
          '')

          # - 1000 (default): General configuration (replaces initExtra)
          ''
            [ -f ~/.config/op/plugins.sh ] && source ~/.config/op/plugins.sh
            # source extra rc in home dir if found
            [ -f ~/.zshrc_extra ] && source ~/.zshrc_extra
          ''

          # - 1500 (mkAfter): Last to run configuration
          (lib.mkAfter ''
            # print profiling results if enabled
            if [[ -n "$ZPROF" ]]; then
              zprof
            fi
          '')
        ];
      };

      # Deferred loading via zsh-defer
      my.zsh-defer =
        let
          omz-jj-aliases = pkgs.runCommand "omz-jj-aliases" { } ''
            mkdir -p $out/share/zsh/plugins/omz-jj-aliases
            grep '^alias ' ${omz}/plugins/jj/jj.plugin.zsh > $out/share/zsh/plugins/omz-jj-aliases/omz-jj-aliases.plugin.zsh
          '';
        in
        {
          enable = true;
          enableCompletion = true;
          enableAutosuggestion = true;
          enableSyntaxHighlighting = true;
          completionInit =
            let
              zcompdump = "${config.programs.zsh.dotDir}/.zcompdump";
            in
            ''
              autoload -U compinit zrecompile && compinit -u -d "${zcompdump}"
              # zcompile the completion dump file if the .zwc is older or missing.
              if command mkdir "${zcompdump}.lock" 2>/dev/null; then
                zrecompile -q -p "${zcompdump}"
                command rm -rf "${zcompdump}.zwc.old" "${zcompdump}.lock"
              fi
            '';
          plugins = [
            # OMZ libs/plugins - load after deferred compinit
            (omzLib "completion")
            (omzLib "directories")
            (omzPlugin "aliases")
            (omzPlugin "git")
            (fromPkg omz-jj-aliases "share/zsh/plugins/omz-jj-aliases/omz-jj-aliases.plugin.zsh")
            (fromPkg pkgs.zsh-you-should-use "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh")
          ];
          initContent = [
            {
              content = ''export YSU_MESSAGE_FORMAT="💡 $(tput setab 22)$(tput setaf 231) %alias $(tput sgr0)"'';
            }
            {
              content = ''
                if [[ $options[zle] = on ]]; then
                  eval "$(${lib.getExe config.programs.atuin.package} init zsh ${lib.escapeShellArgs config.programs.atuin.flags})"
                fi
              '';
            }
          ];
        };

      programs.fzf = {
        enable = true;
        enableZshIntegration = false; # atuin handles ctrl-r, disable the rest
      };
      programs.television.enable = true;

      # Suppress macOS "Last login" message
      home.file.".hushlogin".text = "";

      programs.atuin = {
        enable = true;
        enableZshIntegration = false; # deferred
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
        self.packages.${pkgs.stdenv.hostPlatform.system}.zsh-bench
      ];
      programs.starship = {
        enable = false;
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
