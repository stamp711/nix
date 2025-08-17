{ pkgs, config, ... }:
{
  programs.git = {
    enable = true;
    userName = "Apricity";
    userEmail = "stamp1024@gmail.com";

    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG0Zuk/bYRvsX5WypXgY7aopBeoTNjma1rr6Txtp87JS";
      signByDefault = true;
    };

    delta = {
      enable = true;
      options.side-by-side = true;
    };

    lfs.enable = true;

    extraConfig = {
      init.defaultBranch = "master";
      pull.ff = "only";
      push.autoSetupRemote = true;
      gpg = {
        format = "ssh";
        ssh = {
          allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
          program = "${pkgs.openssh}/bin/ssh-keygen";
        };
      };
    };

    ignores = [
      ".cache/"
      # direnv
      ".direnv/"
      ".envrc"
      # vscode devcontainer
      ".devcontainer/"
      ".vscode/"
      "CLAUDE.local.md"
    ];
  };

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

  # Lazygit
  programs.lazygit.enable = true;

  # Git allowed signers file
  home.file."${config.xdg.configHome}/git/allowed_signers".source = ./allowed_signers;
}
