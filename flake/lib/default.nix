{ self, inputs, ... }:
{
  flake.lib = import ./lib.nix { inherit self inputs; };
}
