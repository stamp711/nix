{ config, lib, ... }:
let
  proxies = config.modelProxies;
in
{
  # This consumer can be imported without enabling either proxy service.
  flake.homeModules.personal =
    { config, ... }:
    {
      # ChatGPT-authenticated Codex discovers the catalog from this endpoint's /models.
      programs.codex.profiles = lib.mkMerge [
        {
          # Codex treats an empty URL as its normal auth-dependent endpoint.
          openai.openai_base_url = "";
        }
        (lib.mapAttrs (_: proxy: { openai_base_url = proxy.baseUrl; }) proxies)
      ];

      # All personal hosts use CLIProxyAPI by default
      programs.codex.settings = config.programs.codex.profiles.cliproxyapi;
    };
}
