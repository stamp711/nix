{
  description = "Automatic NixOS update and garbage collection via nh";

  module =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.my.nixos-maintenance;

      runtimeInputs = [
        config.programs.nh.package
        config.nix.package
      ];

      updateApp = pkgs.writeShellApplication {
        name = "nh-update";
        text = ''
          echo "Updating NixOS configuration via nh"
          NH_BYPASS_ROOT_CHECK=true nh os boot --no-nom "${cfg.flake}" -- --refresh
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
      options.my.nixos-maintenance = {
        autoUpdate = lib.mkEnableOption "automatic NixOS update via nh";
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
          systemd.services.nh-update = {
            description = "NixOS update via nh";
            restartIfChanged = false;
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${updateApp}/bin/nh-update";
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
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${cleanApp}/bin/nh-clean";
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
}
