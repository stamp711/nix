{
  perSystem =
    { pkgs, ... }:
    {
      apps = {
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
      };
    };
}
