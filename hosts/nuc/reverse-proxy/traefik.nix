{
  flake.nixosModules.nuc =
    { config, ... }:
    {
      services.traefik = {
        enable = true;
        # Entry points.
        staticConfigOptions.entryPoints = {
          http = {
            address = ":80";
            http.redirections.entryPoint.to = "https";
          };
          https = {
            asDefault = true;
            address = ":443";
            http.tls = { };
          };
          https-auth = {
            asDefault = true;
            address = "127.0.0.1:18443";
            http.tls = { };
            http.middlewares = [ "authelia@file" ];
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
