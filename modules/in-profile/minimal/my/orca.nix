{ inputs, lib, ... }:
{
  flake.homeModules.my =
    { config, pkgs, ... }:
    let
      cfg = config.my.orca;
      inherit (pkgs.stdenv) hostPlatform;
      orca = inputs.llm-agents.packages.${hostPlatform.system}.orca;
      # The package's main program is the GUI. Both platforms ship the CLI as bin/orca.
      cli = lib.getExe' orca "orca";
      skills = pkgs.runCommand "orca-skills" { } ''
        ORCA_USER_DATA_PATH="$TMPDIR/orca" ${cli} skills install \
          --local --agent universal --skill orca-cli --skill orchestration
        mv .agents/skills "$out"
      '';
      serveArgs = [
        "${pkgs.zsh}/bin/zsh"
        "-lic"
        "exec ${cli} serve --supervise --no-pairing"
      ];
    in
    {
      options.my.orca = {
        enable = lib.mkEnableOption "Orca and its bundled agent skills";
        serve.enable = lib.mkEnableOption "the Orca remote agent server";
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          home.packages = [ orca ];
          my.llm-agents.skills = {
            orca-cli = "${skills}/orca-cli";
            orchestration = "${skills}/orchestration";
          };
        })

        (lib.mkIf cfg.serve.enable {
          assertions = [
            {
              assertion = cfg.enable;
              message = "my.orca.serve.enable requires my.orca.enable.";
            }
          ];

          systemd.user.services.orca-serve = lib.mkIf hostPlatform.isLinux {
            Unit.Description = "Orca remote agent server";
            Install.WantedBy = [ "default.target" ];
            Service = {
              ExecStart = lib.escapeShellArgs serveArgs;
              Restart = "on-failure";
              # Keep agent terminals alive across server restarts.
              KillMode = "process";
            };
          };

          launchd.agents.orca-serve = lib.mkIf hostPlatform.isDarwin {
            enable = true;
            config = {
              ProgramArguments = serveArgs;
              EnvironmentVariables.ORCA_SERVE_RUNTIME = "orcad";
              WorkingDirectory = config.home.homeDirectory;
              KeepAlive.SuccessfulExit = false;
              RunAtLoad = true;
              AbandonProcessGroup = true;
            };
          };
        })
      ];
    };
}
