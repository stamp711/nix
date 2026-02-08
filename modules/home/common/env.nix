# Shell environment: paths, variables, and common aliases
{
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
  };
}
