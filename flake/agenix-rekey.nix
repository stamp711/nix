{
  self,
  inputs,
  config,
  ...
}:
let
  inherit (inputs.nixpkgs) lib;
  rekeyNixos = lib.filterAttrs (
    _: cfg: (cfg.config ? age) && (cfg.config.age ? rekey)
  ) config.flake.nixosConfigurations;
  rekeyHome = lib.filterAttrs (
    _: cfg: (cfg.config ? age) && (cfg.config.age ? rekey)
  ) config.flake.homeConfigurations;
in
{
  flake = {
    # Used for checks
    rekeyNixosConfigurations = rekeyNixos;
    rekeyHomeConfigurations = rekeyHome;

    agenix-rekey = inputs.agenix-rekey.configure {
      userFlake = self;
      nixosConfigurations = rekeyNixos;
      homeConfigurations = rekeyHome;
    };
  };
}
