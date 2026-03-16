{ inputs, ... }:
{
  flake.nixosModules.desktop-apps = {
    imports = [ inputs.solaar.nixosModules.default ];
    services.solaar.enable = true;
  };

  # TODO: manage logi-options+ on darwin
  flake.darwinModules.desktop-apps = { };
}
