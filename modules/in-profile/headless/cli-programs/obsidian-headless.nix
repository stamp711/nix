{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        my.obsidian-vault-watcher
        obsidian-headless
      ];
    };
}
