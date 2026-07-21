# Git configuration with signing, delta, and GitHub CLI & other VCS tools
{ inputs, ... }:
{
  flake.homeModules.cli-programs =
    { lib, pkgs, ... }:
    let
      ghqRoot = if pkgs.stdenv.isDarwin then "~/Developer" else "~/code";

      oyui = inputs.oyui.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      programs.git.enable = true;

      # Some basic settings
      programs.git.settings = {
        init.defaultBranch = "master";
        pull.ff = "only";
        push.autoSetupRemote = true;
        ghq.root = ghqRoot;
        url."ssh://git@github.com/".insteadOf = "https://github.com/";
        aliases.cl = "!git clean -xdf -e .jj";
      };

      # Diff viewers
      programs.difftastic.enable = true;
      programs.difftastic.options.display = "side-by-side-show-both";
      # programs.difftastic.git.enable = true;
      # programs.difftastic.git.diffToolMode = true;
      # programs.difftastic.jujutsu.enable = true;

      programs.delta.enable = true;
      programs.delta.enableGitIntegration = true;
      programs.delta.enableJujutsuIntegration = true;
      programs.delta.options.side-by-side = true;
      programs.delta.options.navigate = true;

      programs.mergiraf.enable = true;
      programs.mergiraf.enableGitIntegration = true;
      programs.mergiraf.enableJujutsuIntegration = true;

      # Global ignores
      programs.git.ignores = [
        "__scratch__/"
        "tmp/"

        # macOS
        ".DS_Store"
        "._*"

        ".cache/"
        # vscode devcontainer
        ".devcontainer/"
        ".vscode/"
        ".claude/"
        "CLAUDE.local.md"
        "__local__/"
        # build artifacts
        ".bundle"
        "compile_commands.json"

        ".worktrees/"
      ];

      # GitHub CLI
      programs.gh = {
        enable = true;
        extensions = [ pkgs.gh-eco ];
        settings = {
          git_protocol = "ssh";
          prompt = "enabled";
          aliases = {
            co = "pr checkout";
            pv = "pr view";
          };
        };
      };

      # Tools
      programs.lazygit.enable = true;
      programs.gitui.enable = true;

      programs.jujutsu.enable = true;
      programs.jujutsu.settings.ui.default-command = [ "log" ];
      programs.jujutsu.settings.ui.show-cryptographic-signatures = true;

      # oyui interactive diff editor
      programs.jujutsu.settings.ui.diff-editor = "oyui";
      programs.jujutsu.settings.ui.diff-instructions = false;
      programs.jujutsu.settings.merge-tools.oyui = {
        program = lib.getExe' oyui "oyui";
        edit-args = [
          "diff"
          "$left"
          "$right"
        ];
      };

      programs.jjui.enable = true;

      # jj/gg diff with diffnav
      programs.zsh.initContent = lib.mkAfter ''
        ggr() { git diff "$@" | diffnav; }
        jjr() { jj diff --git "$@" | diffnav; }
      '';

      home.packages = with pkgs; [
        diffnav
        ghq
        git-filter-repo
        lazyjj
        oyui
      ];
    };
}
