{
  description = "Automatic home-manager update and garbage collection via nh";

  module =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.my.home-maintenance;

      runtimeInputs = [
        config.programs.nh.package
        config.nix.package
      ];

      updateApp = pkgs.writeShellApplication {
        name = "nh-update";
        text = ''
          echo "Updating Home Manager configuration via nh"
          nh home switch --no-nom "${cfg.flake}" -- --refresh
        '';
        inherit runtimeInputs;
      };

      cleanApp = pkgs.writeShellApplication {
        name = "nh-clean";
        text = ''
          echo "Running garbage collection via nh"
          nh clean user --keep-since "${cfg.keepSince}" --keep ${toString cfg.keepGenerations}
        '';
        inherit runtimeInputs;
      };
    in
    {
      options.my.home-maintenance = {
        autoUpdate = lib.mkEnableOption "automatic home-manager update via nh";
        autoClean = lib.mkEnableOption "automatic Nix garbage collection via nh";
        flake = lib.mkOption {
          type = lib.types.str;
          default = "github:stamp711/nix";
        };
        updateDates = lib.mkOption {
          type = lib.types.str;
          default = "daily";
        };
        cleanDates = lib.mkOption {
          type = lib.types.str;
          default = "weekly";
        };
        keepSince = lib.mkOption {
          type = lib.types.str;
          default = "30d";
        };
        keepGenerations = lib.mkOption {
          type = lib.types.int;
          default = 3;
        };
        randomizedDelaySec = lib.mkOption {
          type = lib.types.str;
          default = "4h";
        };
      };

      config = lib.mkMerge [
        # Auto-update
        (lib.mkIf cfg.autoUpdate {
          systemd.user.services.nh-update = {
            Unit.Description = "Home Manager update via nh";
            Unit.X-RestartIfChanged = "false";
            Service = {
              Type = "oneshot";
              ExecStart = "${updateApp}/bin/nh-update";
              Nice = 19;
              CPUSchedulingPolicy = "idle";
              IOSchedulingClass = "idle";
            };
          };
          systemd.user.timers.nh-update = {
            Unit.Description = "Home Manager update timer";
            Install.WantedBy = [ "timers.target" ];
            Timer = {
              OnCalendar = cfg.updateDates;
              Persistent = true;
              RandomizedDelaySec = cfg.randomizedDelaySec;
              FixedRandomDelay = true;
            };
          };

          # macOS
          launchd.agents.nh-update = {
            enable = true;
            config = {
              ProgramArguments = [ "${updateApp}/bin/nh-update" ];
              StartCalendarInterval = lib.hm.darwin.mkCalendarInterval cfg.updateDates;
              Nice = 19;
              LowPriorityIO = true;
              ProcessType = "Background";
            };
          };
        })

        # Auto-clean
        (lib.mkIf cfg.autoClean {
          systemd.user.services.nh-clean = {
            Unit.Description = "Nix garbage collection (user) via nh";
            Service = {
              Type = "oneshot";
              ExecStart = "${cleanApp}/bin/nh-clean";
              Nice = 19;
              CPUSchedulingPolicy = "idle";
              IOSchedulingClass = "idle";
            };
          };
          systemd.user.timers.nh-clean = {
            Unit.Description = "Nix garbage collection (user) timer";
            Install.WantedBy = [ "timers.target" ];
            Timer = {
              OnCalendar = cfg.cleanDates;
              Persistent = true;
              RandomizedDelaySec = cfg.randomizedDelaySec;
              FixedRandomDelay = true;
            };
          };

          # macOS
          launchd.agents.nh-clean = {
            enable = true;
            config = {
              ProgramArguments = [ "${cleanApp}/bin/nh-clean" ];
              StartCalendarInterval = lib.hm.darwin.mkCalendarInterval cfg.cleanDates;
              Nice = 19;
              LowPriorityIO = true;
              ProcessType = "Background";
            };
          };
        })
      ];
    };
}
