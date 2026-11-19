{ inputs, ... }:
{
  flake.homeModules.nuc =
    { pkgs, ... }:
    let
      orca = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.orca;
    in
    {
      home.packages = [ orca ];
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
