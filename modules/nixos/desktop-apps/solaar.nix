{ inputs, ... }:
{
  flake.nixosModules.desktop-apps = {
    imports = [ inputs.solaar.nixosModules.default ];
    services.solaar.enable = true;
  };
}
