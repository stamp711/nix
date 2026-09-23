# Hugging Face model downloader with a web UI and mirror sync between machines.
# https://github.com/bodaay/HuggingFaceModelDownloader
{ lib, self, ... }:
{
  flake.homeModules.my =
    { config, pkgs, ... }:
    let
      cfg = config.my.hfdownloader;
      yaml = pkgs.formats.yaml { };
    in
    {
      options.my.hfdownloader = {
        enable = lib.mkEnableOption "hfdownloader, a Hugging Face model downloader";

        package = lib.mkPackageOption self.packages.${pkgs.stdenv.hostPlatform.system} "hfdownloader" {
          pkgsText = "self.packages.\${system}";
        };

        settings = lib.mkOption {
          inherit (yaml) type;
          default = { };
          example = {
            cache-dir = "/data/huggingface";
            verify = "sha256";
            endpoint = "https://hf-mirror.com";
          };
          description = ''
            Written to {file}`~/.config/hfdownloader.yaml`: `cache-dir`, `verify`,
            `connections`, `max-active`, `retries`, `endpoint`, `proxy`, …
            Command-line flags take precedence. Keep `token` out of here — it would
            land in the Nix store; use {env}`HF_TOKEN` instead.
          '';
        };

        webUI = {
          enable = lib.mkEnableOption "the hfdownloader web UI as a user service";

          address = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            example = "0.0.0.0";
            description = "Address the web UI listens on.";
          };

          port = lib.mkOption {
            type = lib.types.port;
            default = 8090;
            description = "Port the web UI listens on.";
          };

          extraArgs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [
              "--auth-user"
              "me"
            ];
            description = "Extra arguments to `hfdownloader serve`.";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.webUI.enable -> pkgs.stdenv.hostPlatform.isLinux;
            message = "my.hfdownloader.webUI needs systemd user services (Linux only).";
          }
        ];

        home.packages = [ cfg.package ];

        xdg.configFile."hfdownloader.yaml" = lib.mkIf (cfg.settings != { }) {
          source = yaml.generate "hfdownloader.yaml" cfg.settings;
        };

        systemd.user.services.hfdownloader = lib.mkIf cfg.webUI.enable {
          Unit.Description = "hfdownloader web UI";
          Install.WantedBy = [ "default.target" ];
          Service = {
            ExecStart = lib.escapeShellArgs (
              [
                (lib.getExe cfg.package)
                "serve"
                "--addr"
                cfg.webUI.address
                "--port"
                (toString cfg.webUI.port)
              ]
              ++ cfg.webUI.extraArgs
            );
            Restart = "on-failure";
          };
        };
      };
    };
}
