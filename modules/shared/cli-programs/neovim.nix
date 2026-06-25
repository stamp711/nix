# Neovim: the nvf build from packages/nvim.nix.
{ self, ... }:
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      home.packages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.nvim
        pkgs.neovide
      ];
      home.sessionVariables.EDITOR = "nvim";
    };
}
