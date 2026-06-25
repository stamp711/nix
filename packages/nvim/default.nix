# nvf-based neovim — single source of truth (settings in ./settings.nix).
# Home Manager installs this via home.packages (modules/shared/cli-programs/neovim.nix).
# Iterate without switching: `nix run .#nvim`.
{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.nvim =
        (inputs.nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [ ./settings.nix ];
        }).neovim;
    };
}
