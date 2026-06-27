# Neovim: nixvim as `nvim`, lazyvim-nix as `lvim`.
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

      home.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.lvim ];
    };
}
