{
  flake.homeModules.work-codex = {
    programs.codex.profiles.openai.openai_base_url = ""; # connecting directly to OpenAI
  };
}
