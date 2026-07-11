{

  flake.nixosModules.personal = { lib, ... }: {
    services.tailscale.enable = true;
    services.tailscale.useRoutingFeatures = lib.mkDefault "client";
    services.tailscale.extraSetFlags = [ "--ssh" ];
    my.persistence.directories = [ "/var/lib/tailscale" ];
  };

  # Userspace networking; SOCKS5/HTTP proxy on :1055.
  flake.darwinModules.personal = { lib, pkgs, ... }: {
    environment.systemPackages = [ pkgs.tailscale ];
    launchd.daemons.tailscaled.serviceConfig = {
      Label = "com.tailscale.tailscaled";
      ProgramArguments = [
        (lib.getExe' pkgs.tailscale "tailscaled")
        "--tun=userspace-networking"
        "--socks5-server=localhost:1055"
        "--outbound-http-proxy-listen=localhost:1055"
        "--statedir=/var/lib/tailscale"
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

}
