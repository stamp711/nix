# General CLI tools
{ self, pkgs, ... }:
{
  # Multi-language formatter (treefmt wrapped with nixfmt, stylua, prettier, etc.)
  home.packages = with pkgs; [
    self.formatter.${pkgs.stdenv.hostPlatform.system}

    # Search
    fd
    ripgrep

    # General utilities
    assh
    age
    age-plugin-1p
    doxygen
    eternal-terminal
    imgcat
    helix
    just
    netcat
    scc
    sops
    watch
    wakatime-cli
    wget
  ];

  # Modern ls replacement
  programs.lsd = {
    enable = true;
    enableZshIntegration = true;
    settings.icons.theme = "unicode";
  };

  # Smarter cd command
  programs.zoxide.enable = true;

  # Terminal multiplexers
  programs.tmux = {
    enable = true;
    terminal = "xterm-256color";
  };
  programs.zellij.enable = true;

  # Manual pages
  programs.tealdeer = {
    enable = true;
    settings.updates.auto_update = true;
  };

  # System monitoring
  programs.btop.enable = true;

  # Better cat
  programs.bat.enable = true;

  # Modern alternative to the watch command
  programs.hwatch.enable = true;
}
