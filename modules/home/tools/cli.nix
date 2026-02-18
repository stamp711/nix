{
  description = "General CLI tools and utilities";

  module =
    { inputs, pkgs, ... }:
    {
      home.packages = with pkgs; [
        # Search
        fd
        ripgrep

        # General utilities
        assh
        age
        agenix-rekey
        age-plugin-1p
        inputs.age-plugin-op.defaultPackage.${pkgs.stdenv.hostPlatform.system}
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
    };
}
