{
  flake.nixosModules.tailscale =
    { lib, ... }:
    {
      services.tailscale.enable = true;
      services.tailscale.useRoutingFeatures = lib.mkDefault "client";
      services.tailscale.extraSetFlags = [ "--accept-routes" ];
      my.persistence.directories = [ "/var/lib/tailscale" ];
    };
}
