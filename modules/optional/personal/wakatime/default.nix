{ lib, self, ... }:
{
  flake.homeModules.personal-wakatime =
    { config, pkgs, ... }:
    let
      s = self.lib.mkAgeSecret config { rekeyFile = ./wakatime-api-key.age; };
      pkg = pkgs.wakatime-cli;
      home = config.home.homeDirectory;
      ghqRoot = lib.replaceStrings [ "~" ] [ home ] config.programs.git.settings.ghq.root;
    in
    # ghqRoot needs the vcs module
    lib.mkIf config.programs.git.enable {
      age.secrets = s.ageSecret;
      home.packages = [ pkg ];
      home.file.".wakatime.cfg".text = /* ini */ ''
        [settings]
        api_key_vault_cmd = ${pkgs.coreutils}/bin/cat ${s.path}
        # exclude raft.build agent notes
        exclude = /[.]slock/agents/
        # name the project after the repo, not after whoever edited it
        [projectmap]
        ^${ghqRoot}/[^/]+/[^/]+/([^/]+) = {0}
        ^${home}/agents/[^/]+/[^/]+/[^/]+/([^/]+) = {0}
        github[.]com/[^/]+/([^/]+) = {0}
      '';

      # wakatime-cli drains this queue only on --entity runs, and the AI plugins pass none.
      systemd.user.services.wakatime-offline-sync = {
        Unit.Description = "Flush the wakatime offline queue";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkg}/bin/wakatime-cli --sync-offline-activity 0";
        };
      };
      systemd.user.timers.wakatime-offline-sync = {
        Unit.Description = "Wakatime offline queue flush timer";
        Install.WantedBy = [ "timers.target" ];
        Timer = {
          OnStartupSec = "0"; # or OnUnitActiveSec has no first run to count from
          OnUnitActiveSec = "30m";
        };
      };

      launchd.agents.wakatime-offline-sync = {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkg}/bin/wakatime-cli"
            "--sync-offline-activity"
            "0"
          ];
          StartInterval = 1800;
        };
      };
    };

  flake.homeModules.personal.imports = [ self.homeModules.personal-wakatime ];
}
