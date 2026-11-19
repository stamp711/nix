{ inputs, ... }:
{
  flake.homeModules.nuc =
    { pkgs, ... }:
    let
      orca = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.orca;
      skills = pkgs.runCommand "orca-skills" { } ''
        ORCA_USER_DATA_PATH="$TMPDIR/orca" ${orca}/bin/orca skills install \
          --local --agent universal --skill orca-cli --skill orchestration
        mv .agents/skills "$out"
      '';
    in
    {
      home.packages = [ orca ];
      my.llm-agents.skills = {
        orca-cli = "${skills}/orca-cli";
        orchestration = "${skills}/orchestration";
      };
      systemd.user.services.orca-serve = {
        Unit.Description = "Orca remote agent server";
        Install.WantedBy = [ "default.target" ];
        Service = {
          ExecStart = "${pkgs.zsh}/bin/zsh -lic 'exec ${orca}/bin/orca serve --supervise --no-pairing'";
          Restart = "on-failure";
          # Keep agent terminals alive across server restarts.
          KillMode = "process";
        };
      };
    };
}
