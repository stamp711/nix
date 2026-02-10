{
  description = "GitHub token via 1Password for nix, git, and CLI tools";

  module =
    {
      inputs,
      config,
      lib,
      ...
    }:
    let
      secretsDir = "${config.xdg.configHome}/secrets";
    in
    {
      imports = [ inputs.opnix.homeManagerModules.default ];

      programs.onepassword-secrets.enable = true;
      programs.onepassword-secrets.tokenFile = "${secretsDir}/opnix-token";

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
