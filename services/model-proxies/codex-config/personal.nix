{
  # This consumer can be imported without enabling the proxy service.
  flake.homeModules.personal =
    { config, ... }:
    {
      programs.codex.profiles = {
        openai.openai_base_url = ""; # connecting directly to OpenAI
        cpa.openai_base_url = "https://cpa.nuc.apric.net/v1";
      };

      programs.codex.settings = config.programs.codex.profiles.cpa;
    };
}
