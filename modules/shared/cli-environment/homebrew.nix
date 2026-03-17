{
  flake.darwinModules.cli-environment =
    {
      config,
      inputs,
      pkgs,
      ...
    }:
    {
      nix-homebrew = {
        enable = true;
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
      };
    };
}
