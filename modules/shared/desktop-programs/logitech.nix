{ inputs, ... }:
{
  flake.nixosModules.desktop-programs = {
    imports = [ inputs.solaar.nixosModules.default ];
    services.solaar.enable = true;
  };

  # TODO: manage logi-options+ on darwin
  flake.darwinModules.desktop-programs = { };
}
