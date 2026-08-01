# Automatic system and home update/cleanup via nh

let
  maintenanceOptions = lib: {
    autoUpdate = lib.mkEnableOption "automatic update via nh";
    autoClean = lib.mkEnableOption "automatic Nix garbage collection via nh";
    updateDates = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "OnCalendar for the update timer.";
    };
    cleanDates = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
      description = "OnCalendar for the garbage collection timer.";
    };
    keepSince = lib.mkOption {
      type = lib.types.str;
      default = "7d";
      description = "Age below which generations survive garbage collection (`nh clean --keep-since`).";
    };
    keepGenerations = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Generations to keep regardless of age (`nh clean --keep`).";
    };
    randomizedDelaySec = lib.mkOption {
      type = lib.types.str;
      default = "4h";
      description = "RandomizedDelaySec on both timers, so hosts don't all fire at once.";
    };
  };
in
{

  flake.darwinModules.my = { };

  flake.nixosModules.my =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.my.maintenance;

      runtimeInputs = [
        config.programs.nh.package
        config.nix.package
      ];

      updateApp = pkgs.writeShellApplication {
        name = "nh-update";
        text = ''
          echo "Updating NixOS configuration via nh"
          NH_BYPASS_ROOT_CHECK=true nh os boot --no-nom "${config.my.flake}" -- --refresh
        '';
        inherit runtimeInputs;
      };

      cleanApp = pkgs.writeShellApplication {
        name = "nh-clean";
        text = ''
          echo "Running garbage collection via nh"
          nh clean all --keep-since "${cfg.keepSince}" --keep ${toString cfg.keepGenerations}
        '';
        inherit runtimeInputs;
      };
    in
    {
      options.my.maintenance = maintenanceOptions lib;

      config = lib.mkMerge [
        # Auto-update
        (lib.mkIf cfg.autoUpdate {
          systemd.services.nh-update = {
            description = "NixOS update via nh";
            restartIfChanged = false;
            unitConfig.ConditionACPower = true;
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=sleep --who=nh-update --why='NixOS update in progress' --mode=block ${updateApp}/bin/nh-update";
              Nice = 19;
              CPUSchedulingPolicy = "idle";
              IOSchedulingClass = "idle";
            };
          };
          systemd.timers.nh-update = {
            description = "NixOS update timer";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = cfg.updateDates;
              Persistent = true;
              RandomizedDelaySec = cfg.randomizedDelaySec;
              FixedRandomDelay = true;
            };
          };
        })

        # Auto-clean
        (lib.mkIf cfg.autoClean {
          systemd.services.nh-clean = {
            description = "Nix garbage collection (all) via nh";
            unitConfig.ConditionACPower = true;
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=sleep --who=nh-clean --why='Nix garbage collection in progress' --mode=block ${cleanApp}/bin/nh-clean";
              Nice = 19;
              CPUSchedulingPolicy = "idle";
              IOSchedulingClass = "idle";
            };
          };
          systemd.timers.nh-clean = {
            description = "Nix garbage collection (all) timer";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = cfg.cleanDates;
              Persistent = true;
              RandomizedDelaySec = cfg.randomizedDelaySec;
              FixedRandomDelay = true;
            };
          };
        })
      ];
    };

  flake.homeModules.my =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.my.maintenance;

      runtimeInputs = [
        config.programs.nh.package
        config.nix.package
      ];

      updateApp = pkgs.writeShellApplication {
        name = "nh-update";
        text = ''
          echo "Updating Home Manager configuration via nh"
          nh home switch --no-nom "${config.my.flake}" -- --refresh
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
      options.my.maintenance = maintenanceOptions lib;

      config = lib.mkMerge [
        # Auto-update
        (lib.mkIf cfg.autoUpdate {
          systemd.user.services.nh-update = {
            Unit.Description = "Home Manager update via nh";
            Unit.X-RestartIfChanged = "false";
            Unit.ConditionACPower = true;
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
            Unit.ConditionACPower = true;
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
