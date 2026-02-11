{
  description = "Automatic home-manager switch and garbage collection via nh";

  module = {
    imports = [
      (
        {
          config,
          pkgs,
          lib,
          ...
        }:
        let
          cfg = config.services.home-maintenance;

          runtimeInputs = [
            config.programs.nh.package
            config.nix.package
          ];

          switchApp = pkgs.writeShellApplication {
            name = "nh-switch";
            text = ''
              echo "Switching Home Manager configuration via nh"
              nh home switch --no-nom "${cfg.flake}" -- --refresh
            '';
            inherit runtimeInputs;
          };

          cleanApp = pkgs.writeShellApplication {
            name = "nh-clean";
            text = ''
              echo "Running garbage collection via nh"
              nh clean user --keep-since "${cfg.clean.keepSince}"
            '';
            inherit runtimeInputs;
          };
        in
        {
          options.services.home-maintenance = {
            flake = lib.mkOption {
              type = lib.types.str;
              description = "Flake URI for nh.";
            };

            switch.enable = lib.mkEnableOption "periodic home-manager switch via nh";

            switch.dates = lib.mkOption {
              type = lib.types.str;
              default = "daily";
              description = ''
                How often to run nh home switch.
                On Linux, a systemd calendar expression (see systemd.time(7)).
                On macOS, parsed by lib.hm.darwin.mkCalendarInterval.
              '';
            };

            clean.enable = lib.mkEnableOption "periodic garbage collection via nh clean";

            clean.dates = lib.mkOption {
              type = lib.types.str;
              default = "weekly";
              description = ''
                How often to run nh clean.
                Passed to nh's programs.nh.clean.dates.
              '';
            };

            clean.keepSince = lib.mkOption {
              type = lib.types.str;
              default = "30d";
              description = "Keep nix store paths newer than this duration.";
            };
          };

          config = {
            programs.nh.enable = lib.mkIf (cfg.switch.enable || cfg.clean.enable) true;
            programs.nh.flake = lib.mkIf (cfg.switch.enable || cfg.clean.enable) cfg.flake;

            # Linux: nh-switch
            systemd.user.services.nh-switch = lib.mkIf cfg.switch.enable {
              Unit.Description = "Home Manager switch via nh";
              Unit.X-RestartIfChanged = "false";
              Service = {
                Type = "oneshot";
                ExecStart = "${switchApp}/bin/nh-switch";
                Nice = 19;
                CPUSchedulingPolicy = "idle";
                IOSchedulingClass = "idle";
              };
            };
            systemd.user.timers.nh-switch = lib.mkIf cfg.switch.enable {
              Unit.Description = "Home Manager switch timer";
              Install.WantedBy = [ "timers.target" ];
              Timer = {
                OnCalendar = cfg.switch.dates;
                Persistent = true;
              };
            };

            # Linux: nh-clean
            systemd.user.services.nh-clean = lib.mkIf cfg.clean.enable {
              Unit.Description = "Nix garbage collection via nh";
              Service = {
                Type = "oneshot";
                ExecStart = "${cleanApp}/bin/nh-clean";
                Nice = 19;
                CPUSchedulingPolicy = "idle";
                IOSchedulingClass = "idle";
              };
            };
            systemd.user.timers.nh-clean = lib.mkIf cfg.clean.enable {
              Unit.Description = "Nix garbage collection timer";
              Install.WantedBy = [ "timers.target" ];
              Timer = {
                OnCalendar = cfg.clean.dates;
                Persistent = true;
              };
            };

            # macOS: nh-switch
            launchd.agents.nh-switch = lib.mkIf cfg.switch.enable {
              enable = true;
              config = {
                ProgramArguments = [ "${switchApp}/bin/nh-switch" ];
                StartCalendarInterval = lib.hm.darwin.mkCalendarInterval cfg.switch.dates;
                Nice = 19;
                LowPriorityIO = true;
                ProcessType = "Background";
              };
            };

            # macOS: nh-clean
            launchd.agents.nh-clean = lib.mkIf cfg.clean.enable {
              enable = true;
              config = {
                ProgramArguments = [ "${cleanApp}/bin/nh-clean" ];
                StartCalendarInterval = lib.hm.darwin.mkCalendarInterval cfg.clean.dates;
                Nice = 19;
                LowPriorityIO = true;
                ProcessType = "Background";
              };
            };
          };
        }
      )
    ];

    services.home-maintenance = {
      flake = "github:stamp711/nix";
      switch.enable = true;
      switch.dates = "daily";
      clean.enable = true;
      clean.dates = "weekly";
      clean.keepSince = "30d";
    };
  };
}
