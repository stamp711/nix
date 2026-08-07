# General CLI tools and utilities
{ lib, ... }:
{
  flake.homeModules.cli-programs =
    { config, pkgs, ... }:
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
        doxygen
        eternal-terminal
        ghgrab
        imgcat
        helix
        just
        netcat
        osc
        scc
        sops
        watch
        wakatime-cli
        wget

        b4
        public-inbox

        my.even-terminal
      ];

      # Modern ls replacement
      programs.lsd = {
        enable = true;
        enableZshIntegration = true;
      };

      # Smarter cd command
      programs.zoxide = {
        enable = true;
        enableZshIntegration = false; # deferred
      };
      my.zsh-defer.initContent = [
        {
          content = ''eval "$(${lib.getExe config.programs.zoxide.package} init zsh ${lib.concatStringsSep " " config.programs.zoxide.options})"'';
        }
      ];

      programs.yazi = {
        enable = true;
        enableZshIntegration = true;
      };

      # Terminal multiplexers
      programs.tmux = {
        enable = true;
        terminal = "xterm-256color";
      };

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
