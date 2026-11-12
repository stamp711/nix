{
  flake.homeModules.nuc.my.codex.web.enable = true;

  flake.nixosModules.nuc =
    { config, ... }:
    let
      web = config.home-manager.users.${config.my.primaryUser}.my.codex.web;
    in
    {
      services.traefik.dynamicConfigOptions.http = {
        routers.codex-web = {
          rule = "Host(`codex.nuc.apric.net`) || Host(`codex.apric.net`)";
          service = "codex-web";
        };
        services.codex-web.loadBalancer.servers = [
          { url = "http://127.0.0.1:${toString web.port}"; }
        ];
      };
    };
}
