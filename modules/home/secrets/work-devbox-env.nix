{
  description = "Work devbox environment (proxy, paths, toolchain) via 1Password";

  module =
    { config, ... }:
    let
      secretsDir = "${config.xdg.configHome}/secrets";
      envFile = "${secretsDir}/work-devbox-env.sh";
    in
    {
      programs.onepassword-secrets.secrets.workDevboxEnv = {
        reference = "op://Nix Secrets/nix-private/work-devbox-env.sh";
        path = envFile;
      };

      programs.zsh.initContent = ''
        [ -f "${envFile}" ] && source "${envFile}"
      '';
    };
}
