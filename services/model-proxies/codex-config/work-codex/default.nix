{ self, ... }:
{
  flake.homeModules.work-codex =
    { config, ... }:
    let
      headers = self.lib.mkAgeSecret config {
        rekeyFile = ./auth-headers.json.age;
        path = "${config.xdg.configHome}/codex/auth-headers.json";
      };
    in
    {
      age.secrets = headers.ageSecret;

      programs.codex.profiles = {
        openai = {
          openai_base_url = ""; # connecting directly to OpenAI
          # Ensure our custom headers are removed.
          model_providers.openai.http_headers_file = builtins.toFile "codex-empty-headers.json" "{}";
        };
        cpa = {
          openai_base_url = "https://cpa.apric.net/v1";
          model_providers.openai.http_headers_file = headers.path;
        };
      };

      # programs.codex.settings = config.programs.codex.profiles.cpa;
    };
}
