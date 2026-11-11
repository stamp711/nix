{ lib, ... }:
lib.mkMerge [

  {
    flake.nixosModules.nuc = {
      services.authelia.instances."" =
        let
          stateDir = "/var/lib/authelia";
        in
        {
          enable = true;
          secrets = {
            jwtSecretFile = "${stateDir}/secrets/jwt-secret";
            storageEncryptionKeyFile = "${stateDir}/secrets/storage-encryption-key";
          };
          settings = {
            authentication_backend.file.path = "${stateDir}/users.yml";
            storage.local.path = "${stateDir}/db.sqlite3";
            notifier.filesystem.filename = "${stateDir}/notifications.txt";
            server.endpoints.authz.forward-auth = {
              implementation = "ForwardAuth";
              authn_strategies = [
                # order matters
                # {
                #   name = "HeaderAuthorization";
                #   schemes = [ "Basic" ];
                # }
                {
                  name = "HeaderProxyAuthorization";
                  schemes = [ "Basic" ];
                }
                { name = "CookieSession"; }
              ];
            };
            session.cookies = [
              {
                domain = "apric.net";
                authelia_url = "https://auth.apric.net";
              }
            ];
            access_control = {
              default_policy = "deny";
              rules = [
                {
                  subject = "user:stamp";
                  policy = "one_factor";
                  domain_regex = ".*";
                }
                {
                  subject = "user:work";
                  policy = "one_factor";
                  domain = [ "cpa.apric.net" ];
                  # Work clients may use the model API, but not the management UI or API.
                  resources = [ "^/v1/.*$" ];
                }
              ];
            };
          };
        };

      my.persistence.directories = [ "/var/lib/authelia" ];
    };
  }

  {
    flake.nixosModules.nuc =
      { config, ... }:
      {
        services.traefik = {

          staticConfigOptions.entryPoints.tunnel-auth = {
            address = "127.0.0.1:18081";
            forwardedHeaders.trustedIPs = [ "127.0.0.1/32" ];
          };

          dynamicConfigOptions.http =
            let
              autheliaUrl = lib.removeSuffix "/" (
                builtins.replaceStrings [ "tcp://:" "tcp://" ] [ "http://127.0.0.1:" "http://" ]
                  config.services.authelia.instances."".settings.server.address
              );
            in
            {
              middlewares.authelia = {
                forwardAuth = {
                  address = "${autheliaUrl}/api/authz/forward-auth";
                  trustForwardHeader = true;
                };
              };
              routers.authelia = {
                rule = "Host(`auth.nuc.apric.net`) || Host(`auth.apric.net`)";
                entryPoints = [
                  "websecure"
                  "tunnel-auth"
                ];
                service = "authelia";
              };
              services.authelia.loadBalancer.servers = [ { url = autheliaUrl; } ];
            };

        };
      };
  }

]
