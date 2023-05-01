# How to setup

- Install nix
  - To temporarily enable flakes when running nix commands, add `--extra-experimental-features nix-command --extra-experimental-features flakes`.
- Nix-darwin
  - `nix build .#darwinConfigurations.lius-macbook.system`
  - `./result/sw/bin/darwin-rebuild switch --flake .#lius-macbook`
- Standalone home-manager
  - Run `nix run .#homeConfigurations.stamp@darwin.activationPackage`
    - Change `stamp@darwin` as needed
  - To update, run `home-manager switch --flake .#stamp@darwin`
