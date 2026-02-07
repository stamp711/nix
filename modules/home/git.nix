{ pkgs, config, ... }:
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
  programs.delta.options.side-by-side = true;

  # Signing
  programs.git.signing.format = "ssh";
  programs.git.signing.signByDefault = true;
  programs.git.settings.gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
  home.file."${config.xdg.configHome}/git/allowed_signers".text = with config.programs.git; ''
    ${settings.user.email} namespaces="git" ${signing.key}
  '';

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
}
