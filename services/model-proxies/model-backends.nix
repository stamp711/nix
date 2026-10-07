{
  modelBackends.spark = {
    baseUrl = "http://spark-abbc.boar-char.ts.net:8080/v1";
    models."GLM-5.3-Flash-NVFP4" = {
      contextWindow = 262144;
      # Bifrost 2.2.5's fallback maps this model's native "max" effort to "high".
      reasoningEfforts = [
        "low"
        "high"
      ];
      inputModalities = [
        "text"
        "image"
      ];
    };
  };
}
