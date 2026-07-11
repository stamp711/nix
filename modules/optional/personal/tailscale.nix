{

  flake.nixosModules.personal = { lib, ... }: {
    services = {
      tailscale = {
        enable = true;
        useRoutingFeatures = lib.mkDefault "client";
        extraSetFlags = [ "--ssh" ];
      };
    };
    my.persistence.directories = [ "/var/lib/tailscale" ];
  };

  # Userspace networking; SOCKS5/HTTP proxy on :1055.
  flake.darwinModules.personal = { lib, pkgs, ... }: {
    environment.systemPackages = [ pkgs.tailscale ];
    launchd.daemons.tailscaled = {
      command = "${lib.getExe' pkgs.tailscale "tailscaled"} --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 --statedir=/var/lib/tailscale";
      serviceConfig = {
        Label = "com.tailscale.tailscaled";
        RunAtLoad = true;
      };
    };
  };

}
