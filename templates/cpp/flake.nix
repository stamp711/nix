{
  description = "A C++ development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      perSystem =
        { pkgs, ... }:
        {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              # Compilers
              gcc
              clang

              # Build tools
              cmake
              ninja
              meson
              pkg-config

              # Debuggers and profilers
              gdb
              valgrind
              lldb

              # Language servers and formatters
              clang-tools
              ccls
              cmake-language-server

              # Libraries (add as needed)
              # boost
              # fmt
              # catch2
            ];

            shellHook = ''
              echo "C++ development environment"
              echo "gcc version: $(gcc --version | head -n1)"
              echo "clang version: $(clang --version | head -n1)"
              echo "cmake version: $(cmake --version | head -n1)"
            '';
          };

          # Optional: Add formatter
          formatter = pkgs.clang-tools;
        };
    };
}
