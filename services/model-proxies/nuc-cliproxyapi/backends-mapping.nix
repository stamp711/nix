# NOTE: 8.0.4's dynamic Codex catalog gives models without a built-in
# Codex template a short generic coding prompt.
{ config, lib, ... }:
{
  flake.nixosModules.nuc.services.cliproxyapi.settings.openai-compatibility = lib.mapAttrsToList (
    name: backend: {
      inherit name;
      prefix = name;
      base-url = backend.baseUrl;
      # These inference endpoints need no API key or explicit Internet proxy.
      api-key-entries = [ { proxy-url = "direct"; } ];
      # 8.0.4 exposes these capabilities, but has no catalog options for
      # reviewer, prompt, default effort, compaction, summary or verbosity.
      models = lib.mapAttrsToList (model: cfg: {
        name = model;
        max-context-length = cfg.contextWindow;
        input-modalities = cfg.inputModalities;
        thinking.levels = cfg.reasoningEfforts;
      }) backend.models;
    }) config.modelBackends;
}
