# Neovim: hand-rolled nixvim, baked and enabled as `nvim`.
{ self, inputs, ... }:
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      imports = [ inputs.nixvim.homeModules.nixvim ];

      programs.nixvim = {
        enable = true;
        defaultEditor = true;
        nixpkgs.pkgs = pkgs; # our overlaid, allowUnfree pkgs
        imports = [ self.nixvimModules.default ];
      };
    };
}
