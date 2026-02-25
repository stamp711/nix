{
  description = "Automatic home-manager switch and garbage collection via nh";

  module =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      flake = "github:stamp711/nix";
      switchDates = "daily";
      cleanDates = "weekly";
      keepSince = "30d";
      randomizedDelaySec = "4h";

      runtimeInputs = [
        config.programs.nh.package
        config.nix.package
      ];

      switchApp = pkgs.writeShellApplication {
        name = "nh-switch";
        text = ''
          echo "Switching Home Manager configuration via nh"
          nh home switch --no-nom "${flake}" -- --refresh
        '';
        inherit runtimeInputs;
      };

      cleanApp = pkgs.writeShellApplication {
        name = "nh-clean";
        text = ''
          echo "Running garbage collection via nh"
          nh clean user --keep-since "${keepSince}"
        '';
        inherit runtimeInputs;
      };
    in
    {
      programs.nh.enable = true;
      programs.nh.flake = flake;

      # Linux: nh-switch
      systemd.user.services.nh-switch = {
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
      systemd.user.timers.nh-switch = {
        Unit.Description = "Home Manager switch timer";
        Install.WantedBy = [ "timers.target" ];
        Timer = {
          OnCalendar = switchDates;
          Persistent = true;
          RandomizedDelaySec = randomizedDelaySec;
          FixedRandomDelay = true;
        };
      };

      # Linux: nh-clean
      systemd.user.services.nh-clean = {
        Unit.Description = "Nix garbage collection via nh";
        Service = {
          Type = "oneshot";
          ExecStart = "${cleanApp}/bin/nh-clean";
          Nice = 19;
          CPUSchedulingPolicy = "idle";
          IOSchedulingClass = "idle";
        };
      };
      systemd.user.timers.nh-clean = {
        Unit.Description = "Nix garbage collection timer";
        Install.WantedBy = [ "timers.target" ];
        Timer = {
          OnCalendar = cleanDates;
          Persistent = true;
          RandomizedDelaySec = randomizedDelaySec;
          FixedRandomDelay = true;
        };
      };

      # macOS: nh-switch
      launchd.agents.nh-switch = {
        enable = true;
        config = {
          ProgramArguments = [ "${switchApp}/bin/nh-switch" ];
          StartCalendarInterval = lib.hm.darwin.mkCalendarInterval switchDates;
          Nice = 19;
          LowPriorityIO = true;
          ProcessType = "Background";
        };
      };

      # macOS: nh-clean
      launchd.agents.nh-clean = {
        enable = true;
        config = {
          ProgramArguments = [ "${cleanApp}/bin/nh-clean" ];
          StartCalendarInterval = lib.hm.darwin.mkCalendarInterval cleanDates;
          Nice = 19;
          LowPriorityIO = true;
          ProcessType = "Background";
        };
      };
    };
}
