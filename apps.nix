{ pkgs, ... }:
{
  # Show module tree structure
  # Use: nix run .#show-modules [--json|--tree]
  show-modules = {
    type = "app";
    meta.description = "Show module tree with descriptions";
    program = toString (
      pkgs.writeShellScript "show-modules" ''
        bold=$(${pkgs.ncurses}/bin/tput bold)
        dim=$(${pkgs.ncurses}/bin/tput dim)
        reset=$(${pkgs.ncurses}/bin/tput sgr0)

        json=$(${pkgs.nix}/bin/nix eval .#lib.moduleTree --json 2>/dev/null)
        case "$1" in
          --json) echo "$json" | ${pkgs.jq}/bin/jq . ;;
          --tree|"")
            echo "$json" | ${pkgs.jq}/bin/jq -r --arg bold "$bold" --arg dim "$dim" --arg reset "$reset" '
              def tree(prefix):
                (keys | last) as $last |
                to_entries[] |
                (.key == $last) as $is_last |
                (if $is_last then "└── " else "├── " end) as $branch |
                (if $is_last then "    " else "│   " end) as $ext |
                (if .value | type == "string" then ": \($dim)\(.value)\($reset)" else "" end) as $desc |
                "\(prefix)\($branch)\($bold)\(.key)\($reset)\($desc)",
                (if (.value | type) == "object" then .value | tree("\(prefix)\($ext)") else empty end);
              tree("")
            ' ;;
          *) echo "Usage: show-modules [--json|--tree]" ;;
        esac
      ''
    );
  };

  update-inputs = {
    type = "app";
    meta.description = "Update nixpkgs to latest Hydra-cached revision and other inputs to newest";
    program = toString (
      pkgs.writeShellScript "update-nixpkgs" ''
        rev=$(${pkgs.curl}/bin/curl -sL https://channels.nixos.org/nixpkgs-unstable/git-revision)
        echo "Updating to nixpkgs-unstable: $rev"
        ${pkgs.nix}/bin/nix flake update --override-input nixpkgs "github:NixOS/nixpkgs/$rev"
      ''
    );
  };
}
