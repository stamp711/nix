# Nix Configuration

Personal Nix setup using flakes, flake-parts, and home-manager.

## Structure

```
.
├── flake.nix              # Main flake configuration
├── lib/                   # Helper functions (importDir, mkPkgs, mkHome)
├── hosts/                 # Host-specific configurations
├── modules/home/          # Home-manager modules
│   ├── common/            # Shared modules
│   ├── personal/          # Personal-only modules
│   └── work/              # Work-only modules
├── profiles/home/         # Composable profiles (personal, work-laptop, work-devbox)
└── overlays.nix           # Package overlays
```

## Flake Outputs

| Output               | Description                                                  |
| -------------------- | ------------------------------------------------------------ |
| `homeConfigurations` | Named configs: `stamp@Lius-MacBook-Pro`, `work-devbox`, etc. |
| `homeModules`        | Shared home-manager modules                                  |
| `homeProfiles`       | Composable profiles (personal, work-laptop, work-devbox)     |
| `formatter`          | treefmt with nixfmt, stylua, prettier, clang-format, gersemi |
| `deploy`             | deploy-rs configuration for remote hosts                     |
| `templates`          | Project starters (basic, rust, cpp, python)                  |

## Usage

```bash
# First-time setup (no clone needed)
nix --experimental-features 'nix-command flakes' run nixpkgs#nh -- home switch github:stamp711/nix

# Switch configuration (NH_FLAKE is set after first switch)
nh home switch

# Or explicitly specify configuration
nh home switch -c work-devbox
```

### Local Development

```bash
# Deploy to remote host
deploy .#dev
deploy .#work-dev

# Format code (nix, lua, json, c/c++, cmake)
nix fmt

# Update flake inputs
nix flake update

# New project from template
nix flake init -t .#python  # or rust, cpp, basic

# Dev shell
nix develop
```

## Adding a New Host

1. Create `hosts/<name>.nix`:

```nix
{ self, inputs }:
{
  username = "user";
  hostname = "hostname";

  homeConfiguration = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";  # or aarch64-darwin
      config.allowUnfree = true;
    };
    extraSpecialArgs = { inherit self inputs; };
    modules = [
      self.homeProfiles.personal  # or work-laptop, work-devbox
    ];
  };
}
```

2. The host is automatically discovered and added to `homeConfigurations`.

## Systems

- `aarch64-darwin` - Apple Silicon Macs
- `x86_64-linux` - Linux (devboxes, servers)
