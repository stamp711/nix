let
  model = "Qwen3.8-Flash-Next-UD-Q4_K_XL";
  contextWindow = 262144;
  sparkProvider = {
    name = "DGX Spark";
    base_url = "http://spark-abbc.boar-char.ts.net:8080/v1";
    # Allow 11 minutes without an SSE event for long prompt processing.
    # Starts after HTTP headers; model loading has its own server timeout.
    stream_idle_timeout_ms = 660000;
  };
in
{
  flake.homeModules.personal =
    { config, pkgs, ... }:
    let
      # A profile-local catalog prevents OpenAI's codex-auto-review model from
      # being selected against Spark. Keep the installed Codex's fallback prompt.
      modelCatalog =
        pkgs.runCommand "codex-spark-models.json"
          {
            passAsFile = [ "metadata" ];
            metadata = builtins.toJSON {
              models = [
                {
                  slug = model;
                  display_name = model;
                  visibility = "list";
                  priority = 0; # The only model in this profile's picker.
                  supported_in_api = true;
                  default_reasoning_level = "xhigh";
                  supported_reasoning_levels =
                    map
                      (effort: {
                        inherit effort;
                        description = "Reasoning effort: ${effort}";
                      })
                      [
                        "low"
                        "medium"
                        "xhigh"
                      ];
                  # Use the local model for approval decisions, under its real ID.
                  auto_review_model_override = model;
                  context_window = contextWindow;
                  max_context_window = contextWindow;
                  input_modalities = [ "text" ]; # This server has no vision projector.
                  supports_reasoning_summary_parameter = false;
                  # Preserve Codex's fallback tool setup and output budget.
                  shell_type = "unified_exec";
                  support_verbosity = false;
                  experimental_supported_tools = [ ];
                  truncation_policy = {
                    mode = "bytes";
                    # Required by the catalog schema; matches Codex's 10 kB tool-output
                    # fallback in models-manager/src/model_info.rs.
                    limit = 10000;
                  };
                }
              ];
            };
          }
          ''
            ${pkgs.jq}/bin/jq --rawfile instructions \
              ${config.programs.codex.package.src}/codex-rs/models-manager/prompt.md \
              '.models[0].model_messages.instructions_template = $instructions' \
              "$metadataPath" > "$out"
          '';
    in
    {
      # Register the provider for the daemon without selecting a default model.
      programs.codex.settings.model_providers.spark = sparkProvider;

      # select this profile with `codex --profile spark`.
      programs.codex.profiles.spark = {
        inherit model;
        model_provider = "spark";
        model_catalog_json = "${modelCatalog}";
        approvals_reviewer = "auto_review";
        # Matches both the GGUF training context and Spark's --ctx-size.
        model_context_window = contextWindow;
        # Leave 42,144 tokens for generation, tool results and estimation error.
        # Conservative starting point; not a benchmarked compaction threshold.
        model_auto_compact_token_limit = 220000;
        # The GGUF template defaults to xhigh and also accepts medium and low.
        model_reasoning_effort = "xhigh";
        # llama.cpp does not implement the provider-hosted web search tool.
        web_search = "disabled";
      };
    };
}
