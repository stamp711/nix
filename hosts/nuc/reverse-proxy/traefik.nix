{
  flake.nixosModules.nuc =
    { config, ... }:
    {
      services.traefik = {
        enable = true;
        # Entry points.
        staticConfigOptions.entryPoints = {
          web = {
            asDefault = true;
            address = ":80";
            http.redirections.entryPoint.to = "websecure";
          };
          websecure = {
            asDefault = true;
            address = ":443";
            http.tls = { };
          };
          tunnel = {
            address = "127.0.0.1:18080";
            forwardedHeaders.trustedIPs = [ "127.0.0.1/32" ];
          };
        };

        # Read certificate files.
        dynamicConfigOptions.tls.certificates = [
          {
            certFile = "${config.security.acme.certs.nuc.directory}/fullchain.pem";
            keyFile = "${config.security.acme.certs.nuc.directory}/key.pem";
          }
        ];
      };
    };
}
