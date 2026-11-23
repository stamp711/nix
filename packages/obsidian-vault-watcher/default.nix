# Watches an Obsidian vault and dispatches bare #AI tags to an Orca chat.
{
  perSystem =
    { pkgs, ... }:
    {
      packages.obsidian-vault-watcher = pkgs.writers.writePython3Bin "obsidian-vault-watcher" {
        libraries = [ pkgs.python3Packages.watchfiles ];
        # E203 is the slice spacing ruff-format emits and flake8 rejects.
        flakeIgnore = [
          "E203"
          "E501"
        ];
      } (builtins.readFile ./vault-watcher.py);
    };
}
