{
  description = "Git configuration with signing, delta, and GitHub CLI & other VCS tools";

  module =
    {
      self,
      pkgs,
      config,
      lib,
      ...
    }:
    let
      mkAgeSecret =
        file:
        let
          name = self.lib.ageSecretName file;
        in
        {
          inherit name;
          inherit (config.age.secrets.${name}) path;
          rekey.${name}.rekeyFile = file;
        };

      ghqRoot = if pkgs.stdenv.isDarwin then "~/Developer" else "~/code";

      gitIncludes = [
        {
          file = ./git.personal-identity.ini.age;
          condition = "gitdir:${ghqRoot}/github.com/";
        }
        {
          file = ./git.work-identity.ini.age;
          condition = "gitdir:${ghqRoot}/code.byted.org/";
        }
      ];

      jjIdentity = mkAgeSecret ./jj.identity.toml.age;
    in
    {
      programs.git.enable = true;

      # Some basic settings
      programs.git.settings = {
        init.defaultBranch = "master";
        pull.ff = "only";
        push.autoSetupRemote = true;
        ghq = {
          root = ghqRoot;
          user = "stamp711";
        };
      };

      # Delta diff viewer
      programs.delta.enable = true;
      programs.delta.enableGitIntegration = true;
      programs.delta.enableJujutsuIntegration = true;
      programs.delta.options.side-by-side = true;

      # Global ignores
      programs.git.ignores = [
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
      programs.jjui.enable = true;

      home.packages = with pkgs; [
        ghq
        git-filter-repo
      ];

      # Conditional identity (age-encrypted)
      age.secrets = lib.mkMerge (
        (map (inc: (mkAgeSecret inc.file).rekey) gitIncludes) ++ [ jjIdentity.rekey ]
      );

      programs.git.includes = map (inc: {
        inherit (inc) condition;
        inherit (mkAgeSecret inc.file) path;
      }) gitIncludes;

      xdg.configFile."jj/conf.d/identity.toml".source =
        config.lib.file.mkOutOfStoreSymlink jjIdentity.path;
    };
}
