{
  description = "Git configuration with signing, delta, and GitHub CLI & other VCS tools";

  module =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      hasSigningKey = config.programs.git.signing.key != null;
    in
    {
      programs.git.enable = true;

      # Some basic settings
      programs.git.settings = {
        init.defaultBranch = "master";
        pull.ff = "only";
        push.autoSetupRemote = true;
      };

      # Delta diff viewer
      programs.delta.enable = true;
      programs.delta.enableGitIntegration = true;
      programs.delta.enableJujutsuIntegration = true;
      programs.delta.options.side-by-side = true;

      # Signing
      programs.git.signing.format = "ssh";
      programs.git.signing.signByDefault = lib.mkIf hasSigningKey true;
      programs.git.settings.gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
      home.file."${config.xdg.configHome}/git/allowed_signers" = lib.mkIf hasSigningKey {
        text = with config.programs.git; ''
          ${settings.user.email} namespaces="git" ${signing.key}
        '';
      };

      # Global ignores
      programs.git.ignores = [
        ".cache/"
        # direnv
        ".direnv/"
        ".envrc"
        # vscode devcontainer
        ".devcontainer/"
        ".vscode/"
        ".claude/"
        "CLAUDE.local.md"
        "__local__/"
        # build artifacts
        ".bundle"
        "compile_commands.json"
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
      programs.git-worktree-switcher.enable = true;
      programs.gitui.enable = true;

      programs.jujutsu.enable = true;
      programs.jujutsu.settings.ui.default-command = [
        "log"
        "--template"
        "builtin_log_comfortable"
      ];
      programs.jujutsu.settings.user = lib.mkIf (
        config.programs.git.settings ? user
      ) config.programs.git.settings.user;
      programs.jjui.enable = true;

      home.packages = with pkgs; [
        git-filter-repo
      ];
    };
}
