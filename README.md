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
├── overlays.nix           # Package overlays
└── private-stub/          # Empty flake for bootstrapping without SSH key
```

## Flake Outputs

| Output               | Description                                                  |
| -------------------- | ------------------------------------------------------------ |
| `homeConfigurations` | Named configs: `stamp@Lius-MacBook-Pro`, `work-devbox`, etc. |
| `homeModules`        | Shared home-manager modules                                  |
| `homeProfiles`       | Composable profiles (personal, work-laptop, work-devbox)     |
| `formatter`          | treefmt with nixfmt, stylua, prettier, clang-format, gersemi |
| `deploy`             | deploy-rs configuration for remote hosts                     |
| `apps.show-modules`  | Visualize module tree with descriptions                      |

## Usage

```bash
# First-time setup (no clone needed)
nix --experimental-features 'nix-command flakes' run nixpkgs#nh -- home switch github:stamp711/nix

# Switch configuration (NH_FLAKE is set after first switch)
nh home switch

# Or explicitly specify configuration
nh home switch -c work-devbox
```

### Without Private Flake Access

This flake has a private input (`git+ssh://...`) for private information. To use
configurations that don't depend on private information, or to bootstrap without SSH
key access, override the private input with the included stub flake:

```bash
nix --experimental-features 'nix-command flakes' run nixpkgs#nh -- home switch github:stamp711/nix \
  --override-input private github:stamp711/nix?dir=private-stub \
  -c <config-name>
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

# View module tree with descriptions
nix run .#show-modules

# Dev shell
nix develop
```

## Wrapper Pattern

Modules and configurations use a wrapper pattern `{ description, module }` to attach metadata:

```nix
# modules/home/common/example.nix
{
  description = "Example module description";

  module = { pkgs, ... }: {
    home.packages = [ pkgs.hello ];
  };
}
```

The `description` is extracted for visualization (`nix run .#show-modules`), while `module` is
extracted for actual use. Plain functions without wrappers are also supported (description will
be null).

## Adding a New Host

1. Create `hosts/<name>.nix`:

```nix
{ self, inputs }:
let
  system = "x86_64-linux";  # or aarch64-darwin
in
{
  description = "My new host";
  username = "user";
  hostname = "hostname";
  inherit system;

  homeConfiguration = self.lib.mkHome {
    inherit system;
    username = "user";
    modules = [ self.homeProfiles.personal ];  # or work-laptop, work-devbox
  };
}
```

2. The host is automatically discovered and added to `homeConfigurations`.

## Systems

- `aarch64-darwin` - Apple Silicon Macs
- `x86_64-linux` - Linux (devboxes, servers)
