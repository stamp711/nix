{ self, ... }:
{
  flake.homeModules.github-ratelimit-token =
    { config, ... }:
    let
      token = self.lib.mkAgeSecret config ./token.age;
    in
    {
      age.secrets = token.ageSecret;
      # nix ignores GITHUB_TOKEN; bridge via NIX_CONFIG.
      programs.zsh.envExtra = /* zsh */ ''
        GITHUB_TOKEN="$(<${token.path})"
        if [ -n "$GITHUB_TOKEN" ]; then
          export GITHUB_TOKEN
          export NIX_CONFIG="access-tokens = github.com=$GITHUB_TOKEN"
        fi
      '';
    };
}
