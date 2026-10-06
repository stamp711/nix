{
  flake.homeModules.dgx-spark =
    { pkgs, ... }:
    {
      my.hfdownloader = {
        enable = true;
        webUI.enable = true;
      };

      home.packages = [ pkgs.python3Packages.huggingface-hub ];

      # Keep the existing client model list until the registry is updated.
      programs.aichat = {
        enable = true;
        settings = {
          model = "spark:Qwen3.8-Flash-Next-UD-Q4_K_XL";
          clients = [
            {
              type = "openai-compatible";
              name = "spark";
              api_base = "http://127.0.0.1:8080/v1";
              models = [
                { name = "Qwen3.6-35B-A3B-UD-Q6_K_XL"; }
                { name = "Qwen3.8-Flash-Next-UD-Q4_K_XL"; }
              ];
            }
          ];
        };
      };
    };
}
