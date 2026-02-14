{
  description = "Personal git & jj identity via 1Password";

  module =
    { config, ... }:
    let
      secretsDir = "${config.xdg.configHome}/secrets";
      envFile = "${secretsDir}/personal-git.sh";
    in
    {
      programs.onepassword-secrets.secrets.personalGit = {
        reference = "op://Nix Secrets/nix-private/personal-git.sh";
        path = envFile;
      };

      programs.onepassword-secrets.secrets.personalGitAllowedSigners = {
        reference = "op://Nix Secrets/nix-private/personal-git.allowed-signers";
        path = "${secretsDir}/personal-git.allowed-signers";
      };

      programs.zsh.initContent = ''
        [ -f "${envFile}" ] && source "${envFile}"
      '';
    };
}
