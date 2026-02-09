{
  description = "Shared Nix utility functions";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs =
    { nixpkgs, ... }:
    {
      lib = import ./import.nix { inherit (nixpkgs) lib; };
    };
}
