{
  flake.nixvimModules.default = {
    enableMan = false; # nixpkgs pandoc currently lacks Lua support
  };
}
