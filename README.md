# Nix Configuration

Personal Nix setup.

## Structure

```plaintext
.
├── flake.nix
├── flake.systems.nix      # inputs.systems
├── import-dir/            # recursive directory-import flake
├── flake/
│   ├── lib/               # helpers / data
│   ├── modules/           # flake option defs
│   ├── overlays/
│   └── per-system.nix     # apps, formatter, devShell
├── modules/               # nixos & darwin & HM & system-manager
│   ├── in-profile/        # pulled in by the matching profile
│   └── optional/          # opt-in modules
├── profiles/              # minimal < headless < desktop
├── hosts/
│   ├── personal/
│   └── proxy-servers/
├── nixvim/                # neovim config
├── packages/
└── shells/
```

## Usage

```bash
# First-time setup
nix --experimental-features 'nix-command flakes' run nixpkgs#nh -- home switch github:stamp711/nix

# Switch configuration (NH_FLAKE is set after first switch)
nh home switch

# Or explicitly specify configuration
nh home switch -c stamp@GPD

# Deploy to remote host
deploy .#NUC
deploy .#GPD
```
