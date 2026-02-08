{
  self,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nix-index-database.homeModules.nix-index
  ];

  # Multi-language formatter (treefmt wrapped with nixfmt, stylua, prettier, etc.)
  home.packages = [
    self.formatter.${pkgs.stdenv.hostPlatform.system}
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

  # Nix index for command-not-found
  programs.nix-index-database.comma.enable = true;
  programs.nix-index.enable = true;
}
