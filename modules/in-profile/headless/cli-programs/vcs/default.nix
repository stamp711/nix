# Git configuration with signing, delta, and GitHub CLI & other VCS tools
{ self, inputs, ... }:
{
  flake.homeModules.cli-programs =
    {
      lib,
      config,
      pkgs,
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
      ];

      jjIdentity = mkAgeSecret ./jj.personal-identity.toml.age;

      oyui = inputs.oyui.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      imports = [ inputs.hunk.homeManagerModules.default ];

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

      programs.jujutsu.settings."--scope" = [
        {
          "--when".repositories = [ "${ghqRoot}/github.com" ];
          git.push = "stamp711";
        }
        {
          "--when".repositories = [ "${ghqRoot}/github.com/stamp711" ];
          git.push = "origin";
        }
      ];

      programs.jjui.enable = true;

      # hunk review-first diff viewer
      programs.hunk.enable = true;
      programs.hunk.settings = {
        theme = "auto";
        agent_notes = true;
      };
      # bun binary: Nix loader baked in, no RPATH -> picks up system libc and
      # segfaults off NixOS. Can't patchelf (corrupts bun's appended bundle) or
      # use an explicit loader (breaks process.execPath, which hunk self-spawns).
      programs.hunk.package =
        let
          hunk = inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.default;
        in
        if pkgs.stdenv.isDarwin then
          hunk
        else
          pkgs.runCommandLocal "hunk-${hunk.version}"
            {
              nativeBuildInputs = [ pkgs.makeWrapper ];
              inherit (hunk) meta;
            }
            ''
              makeWrapper ${hunk}/bin/hunk $out/bin/hunk \
                --prefix LD_LIBRARY_PATH : ${pkgs.stdenv.cc.libc}/lib
            '';

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
