{ self, inputs, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      packages.nvim = inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
        inherit pkgs;
        module.imports = (self.lib.importDir ./. { collect = true; })._all;
      };
    };
}
