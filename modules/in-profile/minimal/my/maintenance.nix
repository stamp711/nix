# Automatic system and home update/cleanup via nh
{ inputs, lib, ... }:
let
  # Fails when the flake cannot be refreshed from its remote.
  # Falling back to a cached revision is only a warning, and cannot be made an error.
  refreshGuard = flake: /* bash */ ''
    if ! warnings=$(nix flake metadata --refresh "${flake}" 2>&1 >/dev/null); then
      printf '%s\n' "$warnings" >&2
      exit 1
    fi

    case $warnings in
      *"using cached version"* | *"most recent version"*)
        printf '%s\n' "$warnings" >&2
        echo "nh-update: the flake could not be refreshed, not activating" >&2
        exit 1
        ;;
    esac
  '';

  # launchd wants a date where systemd takes a shorthand. Borrowing the
  # user-level half's translation keeps `weekly` meaning one time, not two.
  inherit (import "${inputs.home-manager}/modules/lib/darwin.nix" { inherit lib; })
    mkCalendarInterval
    assertInterval
    ;

  # Vacuous off darwin, where systemd takes any OnCalendar.
  darwinIntervalAssertions = pkgs: cfg: [
    (assertInterval "my.maintenance.updateDates" cfg.updateDates pkgs)
    (assertInterval "my.maintenance.cleanDates" cfg.cleanDates pkgs)
  ];

  # nh, wrapped for a schedule.
  mkApps =
    {
      pkgs,
      config,
      updateCommand,
      cleanCommand,
      asRoot ? true,
    }:
    let
      cfg = config.my.maintenance;
      flake = config.my.flake;
      runtimeInputs = [
        # nix-darwin has no programs.nh.
        (config.programs.nh.package or pkgs.nh)
        config.nix.package
      ];
    in
    {
      updateApp = pkgs.writeShellApplication {
        name = "nh-update";
        text = ''
          ${refreshGuard flake}
          ${lib.optionalString asRoot "NH_BYPASS_ROOT_CHECK=true "}nh ${updateCommand} --no-nom "${flake}" -- --refresh
        '';
        inherit runtimeInputs;
      };
      cleanApp = pkgs.writeShellApplication {
        name = "nh-clean";
        text = ''
          nh clean ${cleanCommand} --keep-since "${cfg.keepSince}" --keep ${toString cfg.keepGenerations}
        '';
        inherit runtimeInputs;
      };
    };

  maintenanceOptions = {
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

  flake.darwinModules.my =
    { config, pkgs, ... }:
    let
      cfg = config.my.maintenance;
      inherit
        (mkApps {
          inherit pkgs config;
          updateCommand = "darwin switch";
          cleanCommand = "all";
        })
        updateApp
        cleanApp
        ;
    in
    {
      options.my.maintenance = maintenanceOptions;

      config = lib.mkMerge [
        { assertions = darwinIntervalAssertions pkgs cfg; }

        # `nh darwin` has no `boot`, so this activates then and there.
        (lib.mkIf cfg.autoUpdate {
          launchd.daemons.nh-update.serviceConfig = {
            ProgramArguments = [ "${updateApp}/bin/nh-update" ];
            StartCalendarInterval = mkCalendarInterval cfg.updateDates;
            Nice = 19;
            LowPriorityIO = true;
            ProcessType = "Background";
          };
        })

        (lib.mkIf cfg.autoClean {
          launchd.daemons.nh-clean.serviceConfig = {
            ProgramArguments = [ "${cleanApp}/bin/nh-clean" ];
            StartCalendarInterval = mkCalendarInterval cfg.cleanDates;
            Nice = 19;
            LowPriorityIO = true;
            ProcessType = "Background";
          };
        })
      ];
    };

  flake.nixosModules.my =
    { config, pkgs, ... }:
    let
      cfg = config.my.maintenance;
      inherit
        (mkApps {
          inherit pkgs config;
          updateCommand = "os boot";
          cleanCommand = "all";
        })
        updateApp
        cleanApp
        ;
    in
    {
      options.my.maintenance = maintenanceOptions;

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
    { config, pkgs, ... }:
    let
      cfg = config.my.maintenance;
      inherit
        (mkApps {
          inherit pkgs config;
          updateCommand = "home switch";
          cleanCommand = "user";
          asRoot = false;
        })
        updateApp
        cleanApp
        ;
    in
    {
      options.my.maintenance = maintenanceOptions;

      config = lib.mkMerge [
        { assertions = darwinIntervalAssertions pkgs cfg; }

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
              StartCalendarInterval = mkCalendarInterval cfg.updateDates;
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
              StartCalendarInterval = mkCalendarInterval cfg.cleanDates;
              Nice = 19;
              LowPriorityIO = true;
              ProcessType = "Background";
            };
          };
        })

      ];
    };
}
