# Nix Configuration

Personal Nix setup.

## Structure

```
.
├── flake.nix
└── flake/
    ├── flakeModules.nix   # Custom flake option defs
    ├── overlays.nix
    ├── lib/               # Helper functions (mkNixos, mkDarwin, mkHome)
    ├── aspects/           # Cross-cutting config modules
    ├── homeModules/
    ├── nixosModules/
    ├── profiles/          # Composable profiles
    ├── hosts/             # Host defs, output nixos/hm/darwin/deploy configs
    │   ├── personal/
    │   ├── work/
    │   └── proxies.nix
    └── per-system/        # Per-system flake outputs (apps, formatter, devShell)
```

## Usage

```bash
# First-time setup
nix --experimental-features 'nix-command flakes' run nixpkgs#nh -- home switch github:stamp711/nix

# Switch configuration (NH_FLAKE is set after first switch)
nh home switch

# Or explicitly specify configuration
nh home switch -c work-devbox

# Deploy to remote host
deploy .#NUC
deploy .#ATT
```
