{
  description = "A Python development environment with uv";

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
              # Python
              python312

              # uv - Fast Python package installer and resolver
              uv

              # Development tools
              ruff # Fast Python linter and formatter
              mypy # Type checker

              # Language servers
              pyright # Python language server
            ];

            shellHook = ''
              echo "Python development environment with uv"
              echo "Python version: $(python --version)"
              echo "uv version: $(uv --version)"

              # Initialize uv project if needed
              if [ ! -f pyproject.toml ]; then
                echo "Tip: Run 'uv init' to initialize a new Python project"
              fi

              # Create .venv if it doesn't exist
              if [ ! -d .venv ]; then
                echo "Creating virtual environment with uv..."
                uv venv
              fi

              # Activate virtual environment
              source .venv/bin/activate
            '';
          };

          # Optional: Add formatter
          formatter = pkgs.ruff;
        };
    };
}
