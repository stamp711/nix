{ self, ... }:
{
  flake.nixosModules.nuc =
    { config, ... }:
    let
      cfDnsToken = self.lib.mkAgeSecret config {
        rekeyFile = ./cloudflare-dns-token.age;
      };
    in
    {
      age.secrets = cfDnsToken.ageSecret;

      # Issue and renew certificates.
      security.acme = {
        acceptTerms = true;
        certs.nuc = {
          domain = "*.nuc.apric.net";
          dnsProvider = "cloudflare";
          dnsResolver = "1.1.1.1:53";
          credentialFiles.CF_DNS_API_TOKEN_FILE = cfDnsToken.path;
          group = "traefik";
          reloadServices = [ "traefik.service" ];
        };
      };

      # Keep the ACME account and certificates across reboots.
      my.persistence.directories = [ "/var/lib/acme" ];
    };
}
