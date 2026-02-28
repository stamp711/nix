# Development tools and language servers
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Security
    _1password-cli

    # Rust
    cargo-expand
    cargo-feature
    cargo-nextest
    cargo-watch
    rustup

    # Python
    uv

    # NodeJS
    volta

    # Language servers
    lua-language-server
    nil
    nixd
    yaml-language-server

    devenv
  ];
}
