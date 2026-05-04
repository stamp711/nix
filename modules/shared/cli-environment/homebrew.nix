{ inputs, ... }:
{
  flake.darwinModules.cli-environment =
    { config, pkgs, ... }:
    {
      nix-homebrew = {
        enable = true;
        # Causes slow shell init: brew shellenv is idempotent and skips fpath
        # prepend when HOMEBREW_PREFIX is inherited, breaking OMZ compinit cache.
        enableZshIntegration = false;
        autoMigrate = true; # auto migrate existing Homebrew installation
        user = config.my.primaryUser;
      };
      # https://github.com/zhaofengli/nix-homebrew/issues/77
      environment.systemPackages = [
        (pkgs.runCommand "brew-completions" { } ''
          mkdir -p $out/share/zsh/site-functions
          cp ${inputs.nix-homebrew.inputs.brew-src}/completions/zsh/_brew $out/share/zsh/site-functions/_brew
        '')
      ];
      homebrew = {
        enable = true;
        taps = [ "buo/cask-upgrade" ];
      };
    };
}
