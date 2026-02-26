---
name: nix-search-tv
description: Search and query NixOS packages, NixOS/Home Manager/nix-darwin options using nix-search-tv. Use when you need to find packages, get package details, view source code locations, or find NixOS/Home Manager/nix-darwin options.
source: https://github.com/0xferrous/agent-stuff/tree/main/skills/nix-search
---

# Nix Search

This skill helps you search NixOS packages and options using `nix-search-tv`, a tool that indexes packages and options from various Nix ecosystem sources.

## Available Indexes

| Index          | Description          |
| -------------- | -------------------- |
| `nixpkgs`      | Nix packages         |
| `home-manager` | Home Manager options |
| `nixos`        | NixOS options        |
| `darwin`       | nix-darwin options   |
| `nur`          | NUR packages         |

## Commands

### 1. List Available Packages/Options

Use `print` to get a list of all packages or options from an index:

```bash
nix-search-tv print --indexes nixpkgs
nix-search-tv print --indexes nixos
nix-search-tv print --indexes nixpkgs,home-manager
```

**Search through packages**:

```bash
$ nix-search-tv print --indexes nixpkgs | grep -i firefox
firefox
firefox-beta
firefox-bin
firefox-unwrapped
firefox-esr
firefox_decrypt
firefoxpwa
```

**Note**: First run downloads and indexes data (takes a few minutes).

### 2. Get Package/Option Details

Use `preview` to get detailed information about a package or option:

```bash
nix-search-tv preview --indexes nixpkgs firefox
nix-search-tv preview --indexes nixos boot.loader.systemd-boot.enable
```

**Get JSON output** (useful for programmatic parsing):

```bash
nix-search-tv preview --indexes nixpkgs --json firefox
```

The `--json` option outputs raw package data as JSON with the package key included as the `_key` field. This is ideal for agent automation and script parsing.

**Example output**:

```
firefox
(147.0.2)
Web browser built from Firefox source tree

homepage
http://www.mozilla.com/en-US/firefox/

license (free)
MPL-2.0

main program
$ firefox

platforms
x86_64-linux
aarch64-linux
x86_64-darwin
aarch64-darwin
```

### 3. Get Source Code Location

Use `source` to get the link to the package or option's source code:

```bash
$ nix-search-tv source --indexes nixpkgs firefox
https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/networking/browsers/firefox/wrapper.nix
```

### 4. Get Homepage

Use `homepage` to get the package's homepage URL:

```bash
$ nix-search-tv homepage --indexes nixpkgs firefox
http://www.mozilla.com/en-US/firefox/
```

## Tips

- First run downloads and indexes data; subsequent runs use cached data.
- When using multiple indexes, package names are prefixed (e.g., `nixpkgs/ firefox`).
- Set `NO_COLOR=1` to disable ANSI colored output from preview command.
- Use `--json` flag with `preview` for programmatic/agent-friendly output.

## Agent Usage Patterns

### Search and get details:

```bash
PACKAGE=$(nix-search-tv print --indexes nixpkgs | grep -i "neovim" | head -1)
nix-search-tv preview --indexes nixpkgs "$PACKAGE"
```

### Get structured package data for automation:

```bash
nix-search-tv preview --indexes nixpkgs --json ripgrep | jq '{
  name,
  version,
  description,
  homepage,
  license
}'
```

## Troubleshooting

**"cache.txt" not found**: Run `nix-search-tv print` to trigger initial indexing.

**Stale data**: Check `update_interval` in config, or manually re-index by removing the cache directory:

```bash
rm -rf ~/.cache/nix-search-tv/<index-name>
nix-search-tv print --indexes <index-name>
```

**Multiple indexes confusion**: Use explicit `--indexes` flag or the `{index}/ ` prefix format.
