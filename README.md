# Nix Configuration

Personal Nix setup using flakes, flake-parts, and home-manager.

## Structure

```
.
├── flake.nix              # Main flake configuration
├── shell.nix              # Development shell
├── lib/                   # Helper functions (importDir, loadDir)
├── hosts/                 # Host-specific configurations
├── modules/
│   ├── home/              # Shared home-manager modules
│   ├── home-personal/     # Personal-only modules
│   └── home-work/         # Work-only modules
├── profiles/home/         # Composable profiles (personal, work-laptop, work-devbox)
├── overlays.nix           # Package overlays
└── templates/             # Project starters (basic, rust, cpp, python)
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
# First-time setup
nix --experimental-features 'nix-command flakes' run home-manager -- switch --flake .

# Switch configuration
home-manager switch --flake .#stamp@Lius-MacBook-Pro

# Or use a template config (for devboxes)
home-manager switch --flake .#work-devbox

# Deploy to remote host
deploy .#dev
deploy .#work-dev

# Format code (nix, lua, json, c/c++, cmake)
nix fmt
# or globally
treefmt

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
