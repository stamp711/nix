let
  sparkProvider = {
    name = "DGX Spark";
    base_url = "http://spark-abbc.boar-char.ts.net:8080/v1";
    wire_api = "responses";
    requires_openai_auth = false;
    supports_websockets = false;
    # Allow 11 minutes without an SSE event for long prompt processing.
    # Starts after HTTP headers; model loading has its own server timeout.
    stream_idle_timeout_ms = 660000;
  };
in
{
  flake.homeModules.personal = {
    # Register the provider for the daemon without selecting a default model.
    programs.codex.settings.model_providers.spark = sparkProvider;

    # select this profile with `codex --profile spark`.
    programs.codex.profiles.spark = {
      model = "Qwen3.8-Flash-Next-UD-Q4_K_XL";
      model_provider = "spark";
      # Matches both the GGUF training context and Spark's --ctx-size.
      model_context_window = 262144;
      # Leave 42,144 tokens for generation, tool results and estimation error.
      # Conservative starting point; not a benchmarked compaction threshold.
      model_auto_compact_token_limit = 220000;
      # The GGUF template defaults to xhigh and also accepts medium and low.
      model_reasoning_effort = "xhigh";
      # Omit the summary request: llama.cpp only handles reasoning.effort.
      model_reasoning_summary = "none";
      # llama.cpp does not implement the provider-hosted web search tool.
      web_search = "disabled";

      model_providers.spark = sparkProvider;
    };
  };
}
