{ self, ... }:
{
  flake.homeModules.work =
    { config, ... }:
    let
      headers = self.lib.mkAgeSecret config {
        rekeyFile = ./cloudflare-access.json.age;
        path = "${config.xdg.configHome}/codex/cloudflare-access.json";
      };
    in
    {
      age.secrets = headers.ageSecret;

      programs.codex.settings = {
        openai_base_url = "https://cpa.apric.net/v1";
        model_providers.openai = {
          name = "OpenAI";
          http_headers_file = headers.path;
        };
      };
    };
}
