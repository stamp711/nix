# Defaults + enablement for the mihomo proxy router (see my/proxy-router.nix).
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
        proxies = [
          "surge-local"
          "surge-lan"
          "DIRECT"
        ];
        url = "http://www.qualcomm.cn/generate_204";
        interval = 60;
      };

      fallbackProxyGroups.gate = {
        proxies = [
          "surge-local"
          "charon"
          "surge-lan"
        ];
        url = "http://www.google.com/generate_204";
        interval = 60;
      };

      gatedDomains = [
        "google.com"
        "github.com"
        "deepwiki.com"
        "linear.app"
        "anthropic.com"
        "claude.ai"
        "claude.com"
        "cdn.usefathom.com"
        "datadoghq.com"
      ];

      directDomains = [ ];

      directIPs = [
        "127.0.0.0/8"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "::1/128"
        "fc00::/7"
      ];

    };
  };
}
