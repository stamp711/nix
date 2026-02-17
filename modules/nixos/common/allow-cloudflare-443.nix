{
  description = "Allow port 443 from Cloudflare IPs only via nftables";

  module =
    { inputs, ... }:
    let
      data = builtins.fromJSON (builtins.readFile inputs.cloudflare-ips);
      ipv4 = builtins.concatStringsSep ", " data.result.ipv4_cidrs;
      ipv6 = builtins.concatStringsSep ", " data.result.ipv6_cidrs;
    in
    {
      networking.nftables.enable = true;

      networking.firewall.extraInputRules = ''
        ip saddr { ${ipv4} } tcp dport 443 accept
        ip6 saddr { ${ipv6} } tcp dport 443 accept
      '';
    };
}
