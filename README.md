# Nix Configuration

Personal Nix setup with flakes and flake-parts.

## Structure

- `flake.nix` - Main flake configuration
- `shell.nix` - Development shell
- `home/` - Home-manager configuration
  - `packages.nix` - Standalone packages
  - `shell.nix` - Zsh + starship
  - `cli-tools.nix` - CLI utilities
  - `git/` - Git config + SSH signing
- `overlays/` - Package overlays (includes `pkgs-intel` for x86 on Apple Silicon)
- `templates/` - Project starters (basic, rust, cpp, python)

## Setup

```bash
# Install Nix
sh <(curl -L https://nixos.org/nix/install) --daemon

# First-time activation
nix --experimental-features 'nix-command flakes' run home-manager -- switch --flake .

# Updates
nix flake update
home-manager switch --flake .

# Purge old generations
nix-clean
```

## Quick Commands

```bash
# Dev shell
nix develop

# Format (uses nixfmt-tree)
nix fmt

# Update flakes
nix flake update

# New project from template
nix flake init -t .#python  # or rust, cpp, basic
```

## Notes

- Add packages: Edit `home/packages.nix`
- Add configured programs: Edit relevant files in `home/`
- Systems: aarch64-darwin, x86_64-linux
