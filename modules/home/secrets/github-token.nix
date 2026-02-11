{
  description = "GitHub token via 1Password for nix, git, and CLI tools";

  module =
    { config, ... }:
    let
      secretsDir = "${config.xdg.configHome}/secrets";
    in
    {
      # Environment variable for gh, git, etc.
      programs.onepassword-secrets.secrets.githubToken = {
        reference = "op://Nix Secrets/Github Token/credential";
        path = "${secretsDir}/github-token";
      };
      programs.zsh.initContent = ''
        export GITHUB_TOKEN="$(cat ${secretsDir}/github-token)"
      '';

      # For nix.conf
      programs.onepassword-secrets.secrets.nixAccessToken = {
        reference = "op://Nix Secrets/Github Token/nix.conf";
        path = "${secretsDir}/nix-access-tokens.conf";
      };
      nix.extraOptions = "!include ${secretsDir}/nix-access-tokens.conf";
    };
}
