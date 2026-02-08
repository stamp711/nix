{
  description = "Automatic home-manager switch and garbage collection via nh";

  module = {
    imports = [
      (
        { config, lib, ... }:
        let
          cfg = config.services.home-maintenance;
          nhExe = lib.getExe config.programs.nh.package;
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

            programs.nh.clean.enable = lib.mkIf cfg.clean.enable true;
            programs.nh.clean.dates = lib.mkIf cfg.clean.enable cfg.clean.dates;
            programs.nh.clean.extraArgs = lib.mkIf cfg.clean.enable "--keep-since ${cfg.clean.keepSince}";

            # Linux: systemd user service + timer
            systemd.user = lib.mkIf cfg.switch.enable {
              services.nh-switch = {
                Unit.Description = "Home Manager switch via nh";
                Service = {
                  Type = "oneshot";
                  ExecStart = "${nhExe} home switch -- --refresh";
                  Nice = 19;
                  CPUSchedulingPolicy = "idle";
                  IOSchedulingClass = "idle";
                };
              };
              timers.nh-switch = {
                Unit.Description = "Home Manager switch timer";
                Install.WantedBy = [ "timers.target" ];
                Timer = {
                  OnCalendar = cfg.switch.dates;
                  Persistent = true;
                };
              };
            };

            # macOS: launchd agent
            launchd.agents.nh-switch = lib.mkIf cfg.switch.enable {
              enable = true;
              config = {
                ProgramArguments = [
                  nhExe
                  "home"
                  "switch"
                  "--"
                  "--refresh"
                ];
                StartCalendarInterval = lib.hm.darwin.mkCalendarInterval cfg.switch.dates;
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
