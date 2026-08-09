{
  flake.homeModules.core =
    { config, ... }:
    {
      # Default secretsDir is a shell expression, override with a literal path instead.
      # It's only a symlink, the actual secrets are still in an ephemeral runtime dir.
      age.secretsDir = "${config.xdg.dataHome}/agenix";
    };
}
