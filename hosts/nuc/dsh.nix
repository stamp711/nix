{
  flake.nixosModules.nuc.services.traefik.dynamicConfigOptions.http = {
    routers.dsh = {
      rule = "Host(`dsh.nuc.apric.net`) || Host(`dsh.apric.net`)";
      service = "dsh";
    };
    services.dsh.loadBalancer.servers = [
      { url = "http://127.0.0.1:3080"; }
    ];
  };

  flake.homeModules.nuc =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.dsh
        pkgs.pnpm
        pkgs.bubblewrap
      ];

      systemd.user.services.dsh-web = {
        Unit.Description = "dsh web";
        Install.WantedBy = [ "default.target" ];
        Service = {
          ExecStart = "${pkgs.zsh}/bin/zsh -lc 'exec ${pkgs.dsh}/bin/dsh web --no-open --public-url https://dsh.nuc.apric.net/ --trusted-host dsh.nuc.apric.net dsh.apric.net'";
          Restart = "on-failure";
        };
      };
    };
}
