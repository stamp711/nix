# Defaults + enablement for the mihomo proxy router.
{ self, lib, ... }:
{
  flake.homeModules.cli-environment = {
    my.proxyRouter = {
      enable = true;
      enableZshIntegration = true;

      externalController = "127.0.0.1:9090";

      proxies = {
        surge-local = {
          type = "socks5";
          server = "127.0.0.1";
          port = 6153;
        };
        surge-lan = {
          type = "socks5";
          server = "10.0.10.10";
          port = 6153;
        };
        charon = {
          type = "http";
          server = "127.0.0.1";
          port = 6150;
        };
      };

      fallbackProxyGroups.auto = {
        proxies = lib.mkMerge [
          [
            "surge-local"
            "surge-lan"
          ]
          (lib.mkOrder 9999 [ "DIRECT" ])
        ];
        url = "http://www.qualcomm.cn/generate_204";
        interval = 60;
      };

      fallbackProxyGroups.native = {
        proxies = [
          "surge-local"
          "surge-lan"
          "charon"
        ];
        url = "http://www.google.com/generate_204";
        interval = 60;
      };

      nativeDomains = self.lib.gatedDomains;

      directDomains = [ "ts.net" ];

      directIPs = [
        "127.0.0.0/8"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "100.64.0.0/10" # tailnet CGNAT; ULA already covered by fc00::/7
        "::1/128"
        "fc00::/7"
      ];

    };
  };
}
