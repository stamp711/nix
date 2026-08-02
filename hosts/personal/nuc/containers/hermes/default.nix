# Agent sandboxes: the raft.build daemon, the Hermes agent and the Multica
# daemon, one container each.
{ lib, self, ... }:
{
  flake.nixosModules.nuc =
    { config, ... }:
    let
      home = config.users.users.${config.my.primaryUser}.home;
    in
    {
      my.containers.hermes = {
        macvlan = "enp4s0";
        hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJSkkfNGI3x2T3HWlgV3srGzd7Rj7VborpcFaQAGk/+c";
        userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEUMf5TI9bZBu1f4RgAAu7vrmPlLqqZ7xTq5tkHIjYQu";
        hostDirs = [ "${home}/code" ];
        nixosModules = [
          self.profiles.nixos.headless
          (
            { config, ... }:
            let
              serve = self.lib.mkAgeSecret config {
                rekeyFile = ./dashboard-auth.env.age;
                generator.script =
                  { pkgs, ... }:
                  ''
                    echo "HERMES_DASHBOARD_BASIC_AUTH_USERNAME=${config.my.primaryUser}"
                    echo "HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=$(${pkgs.openssl}/bin/openssl rand -base64 24)"
                    echo "HERMES_DASHBOARD_BASIC_AUTH_SECRET=$(${pkgs.openssl}/bin/openssl rand -base64 32)"
                  '';
              };
              webui = self.lib.mkAgeSecret config {
                rekeyFile = ./webui-auth.env.age;
                generator.script =
                  { pkgs, ... }:
                  ''
                    echo "HERMES_WEBUI_PASSWORD=$(${pkgs.openssl}/bin/openssl rand -base64 24)"
                  '';
              };
            in
            {
              age.secrets = lib.mkMerge [
                serve.ageSecret
                webui.ageSecret
              ];
              my.hermes = {
                enable = true;
                serve = {
                  enable = true;
                  host = "0.0.0.0";
                  authFile = serve.path;
                };
                webui = {
                  enable = true;
                  host = "0.0.0.0";
                  authFile = webui.path;
                };
              };
            }
          )
        ];
        homeModules = [ self.profiles.homeManager.headless ];
      };
    };
}
