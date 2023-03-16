# How to setup

- Install nix
- Run `nix run .#homeConfigurations.stamp@darwin.activationPackage`
  - Change `stamp@darwin` as needed
  - To temporarily enable flakes, add `--extra-experimental-features nix-command --extra-experimental-features flakes`
- To update, run `home-manager switch --flake .#stamp@darwin`
