let
  daemonProxyEnvironment =
    config:
    let
      port = config.home-manager.users.${config.my.primaryUser}.my.proxyRouter.port or 7890;
      endpoint = "127.0.0.1:${toString port}";
    in
    {
      http_proxy = "http://${endpoint}";
      https_proxy = "http://${endpoint}";
      all_proxy = "socks5h://${endpoint}";
      no_proxy = "localhost,127.0.0.1";
    };
in
{
  flake.nixosModules.cli-environment = { config, ... }: {
    systemd.services.nix-daemon.environment = daemonProxyEnvironment config;
  };

  flake.darwinModules.cli-environment = { config, ... }: {
    launchd.daemons.nix-daemon.environment = daemonProxyEnvironment config;
  };
}
