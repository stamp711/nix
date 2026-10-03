{
  flake.homeModules.nuc =
    { pkgs, ... }:
    {

      home.packages = [
        pkgs.cloudflared # for t3code connect
      ];

      my.codex.appServer = {
        enable = true;
        remoteControl = true;
      };

      programs.t3code.server = {
        enable = true;
        extraArgs = [
          "--host"
          "0.0.0.0"
          "--port"
          "3773"
        ];
      };

    };
}
