{
  flake.nixosModules.nuc =
    { config, ... }:
    {
      services.traefik = {
        enable = true;
        # Entry points.
        staticConfigOptions.entryPoints = {
          web = {
            address = ":80";
            http.redirections.entryPoint.to = "websecure";
          };
          websecure = {
            address = ":443";
            asDefault = true;
            http.tls = { };
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
