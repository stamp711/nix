{
  modelBackends.spark = {
    baseUrl = "http://spark-abbc.boar-char.ts.net:8080/v1";
    models."Qwen3.8-Flash-Next-UD-Q4_K_XL" = {
      contextWindow = 262144;
      reasoningEfforts = [
        "low"
        "medium"
        "xhigh"
      ];
      inputModalities = [ "text" ]; # This server has no vision projector.
    };
  };
}
