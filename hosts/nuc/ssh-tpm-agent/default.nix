{ lib, self, ... }:
{
  flake.homeModules.nuc =
    { config, ... }:
    let
      tpmKey = self.lib.mkAgeSecret config {
        rekeyFile = ./key.tpm.age;
        generator.script =
          { pkgs, file, ... }:
          ''
            if [[ "$(< /proc/sys/kernel/hostname)" != NUC ]]; then
              echo "Generate this key on NUC." >&2
              exit 1
            fi

            dir=$(mktemp -d) || exit
            trap 'rm -rf "$dir"' EXIT

            # Supply an empty PIN without an interactive prompt.
            export SSH_ASKPASS_REQUIRE=force SSH_ASKPASS=${pkgs.coreutils}/bin/true

            ${lib.getExe' pkgs.ssh-tpm-agent "ssh-tpm-keygen"} -C nuc-tpm -f "$dir/key" >&2 || exit
            cp "$dir/key.pub" ${lib.escapeShellArg (lib.removeSuffix ".tpm.age" file + ".pub")} || exit
            cat "$dir/key.tpm"
          '';
      };
    in
    {
      age.secrets = tpmKey.ageSecret;

      my.ssh-agent-mux.sockets = lib.mkBefore [ config.home.sessionVariables.SSH_TPM_AUTH_SOCK ];

      services.ssh-tpm-agent = {
        enable = true;
        keyDir = builtins.dirOf tpmKey.path;
      };

      systemd.user.services.ssh-tpm-agent.Unit = {
        Requires = [ "agenix.service" ];
        After = [ "agenix.service" ];
        X-Restart-Triggers = [ (builtins.hashFile "sha256" ./key.tpm.age) ];
      };
    };
}
