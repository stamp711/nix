# packages.nvim, built from flake.nixvimModules.default by nixvim's flakeModule.
{ self, inputs, ... }:
{
  nixvim.packages.enable = true;

  perSystem =
    { pkgs, ... }:
    {
      nixvimConfigurations.nvim = inputs.nixvim.lib.evalNixvim {
        modules = [
          { nixpkgs.pkgs = pkgs; }
          self.nixvimModules.default
        ];
      };
    };
}
