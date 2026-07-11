{
  flake.nixosModules.personal = { lib, ... }: {
    services.tailscale.enable = true;
    services.tailscale.useRoutingFeatures = lib.mkDefault "client";
    services.tailscale.extraSetFlags = [ "--ssh" ];
    my.persistence.directories = [ "/var/lib/tailscale" ];
  };
}
