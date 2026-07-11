{
  flake.nixosModules.tailscale =
    { lib, ... }:
    {
      services.tailscale.enable = true;
      services.tailscale.useRoutingFeatures = lib.mkDefault "client";
      services.tailscale.extraSetFlags = [
        "--accept-routes"
        "--ssh"
      ];
      my.persistence.directories = [ "/var/lib/tailscale" ];
    };
}
