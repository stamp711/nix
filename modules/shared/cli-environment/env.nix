# Shell environment paths, variables, and aliases
{
  flake.homeModules.cli-environment = {
    home.sessionPath = [
      "$HOME/.local/bin"
      "$XDG_DATA_HOME/bob/nvim-bin"
      "$VOLTA_HOME/bin"
      "$HOME/.cargo/bin"
      "/opt/homebrew/bin"
    ];

    home.sessionVariables = {
      VOLTA_HOME = "$HOME/.volta";
      COLORTERM = "truecolor";
    };

    home.shellAliases = {
      nix-init = "nix flake init -t github:the-nix-way/dev-templates#";
      sshproxy = "ssh -R 6152:127.0.0.1:6152 -R 6153:127.0.0.1:6153";
      # zsh startup benchmarking
      zsh-time = "hyperfine --warmup 3 'zsh -ic exit'";
      zsh-prof = "ZPROF=1 zsh -ic exit";
    };
  };
}
