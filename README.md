# Nix Configuration

Personal NixOS and nix-darwin configurations, with reusable modules and profiles
for downstream Home Manager and system-manager configurations.

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
├── profiles/              # minimal < headless < desktop, plus work
├── hosts/                 # NUC, Surface, Macs, DGX Sparks and proxy servers
├── services/              # deployments, exposed service data and client integration
├── nixvim/                # neovim config
├── packages/
└── shells/
```

## Usage

Run these commands from the checkout. The configured hosts embed Home Manager,
so switching the system also updates the user's home configuration.

```bash
# NixOS (selects the current hostname)
nh os switch .

# macOS (selects the current hostname)
nh darwin switch .

# Or explicitly select the local machine's configuration
nh os switch . --hostname NUC
nh darwin switch . --hostname Lius-MacBook

# Deploy the configured remote proxy servers
nix develop -c deploy .#VIA
nix develop -c deploy .#NURO
```

Omit `.` to use `NH_FLAKE`; pass `.` to include local changes. If `nh` is not
installed yet, use `nix run nixpkgs#nh -- os switch .` on NixOS or
`nix run nixpkgs#nh -- darwin switch .` on macOS with an existing nix-darwin setup.

This repository exports no standalone `homeConfigurations`. Downstream flakes
can use `lib.mkHome`, `lib.mkSystem`, and the exported modules and profiles.
`profiles.homeManager.work` groups the work Codex configuration, GitHub rate-limit
token, and WakaTime configuration for downstream imports.
