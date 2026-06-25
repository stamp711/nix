# Home Manager installs this via home.packages (modules/shared/cli-programs/neovim.nix).
# Iterate without a home-manager switch: `nix run .#nvim`.
{ self, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.nvim =
        (inputs.nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = (self.lib.importDir ./. { collect = true; })._all;
        }).neovim;
    };
}
