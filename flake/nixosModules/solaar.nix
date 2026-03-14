{ inputs, ... }:
{
  flake.nixosModules.solaar = {
    imports = [ inputs.solaar.nixosModules.default ];
    services.solaar.enable = true;
  };
}
