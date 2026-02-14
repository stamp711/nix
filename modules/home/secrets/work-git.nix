{
  description = "Work git & jj identity via 1Password";

  module =
    { config, ... }:
    let
      secretsDir = "${config.xdg.configHome}/secrets";
      envFile = "${secretsDir}/work-git.sh";
    in
    {
      programs.onepassword-secrets.secrets.workGit = {
        reference = "op://Nix Secrets/nix-private/work-git.sh";
        path = envFile;
      };

      programs.onepassword-secrets.secrets.workGitAllowedSigners = {
        reference = "op://Nix Secrets/nix-private/work-git.allowed-signers";
        path = "${secretsDir}/work-git.allowed-signers";
      };

      programs.zsh.initContent = ''
        [ -f "${envFile}" ] && source "${envFile}"
      '';
    };
}
