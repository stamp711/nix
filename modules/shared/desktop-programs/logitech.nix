{ inputs, ... }:
{
  flake.nixosModules.desktop-programs = {
    imports = [ inputs.solaar.nixosModules.default ];
    services.solaar.enable = true;
  };

  flake.darwinModules.desktop-programs = {
    homebrew.casks = [ "logi-options+" ];
  };
}
