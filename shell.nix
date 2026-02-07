# Development shell for Nix configuration
# Works with both `nix-shell` and `nix develop`
{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  name = "nix-config";
  packages = with pkgs; [
    # Nix language tools
    nil
    nixd
    nixfmt

    # Nix linters and utilities
    statix
    deadnix
    nix-output-monitor

    # For updating flake inputs
    (pkgs.writeShellScriptBin "update-flake" ''
      echo "Updating flake inputs..."
      nix flake update
    '')
  ];

  shellHook = ''
    echo "Nix config development shell"
    echo "Available tools:"
    echo "  - nil/nixd: Nix language servers"
    echo "  - nixfmt: Format Nix files"
    echo "  - statix: Lint Nix files"
    echo "  - deadnix: Find dead Nix code"
    echo "  - update-flake: Update all flake inputs"
  '';
}
