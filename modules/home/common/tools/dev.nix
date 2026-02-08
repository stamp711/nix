{
  description = "Development tools and language servers";

  module =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        # Binary analysis
        elf-info
        binsider

        # Security
        _1password-cli

        # C/C++
        cmake

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
      ];
    };
}
