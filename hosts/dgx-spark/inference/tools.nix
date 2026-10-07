{ config, lib, ... }:
let
  backend = config.modelBackends.spark;
in
{
  flake.homeModules.dgx-spark =
    { pkgs, ... }:
    {
      my.hfdownloader = {
        enable = true;
        webUI.enable = true;
      };

      home.packages = [ pkgs.python3Packages.huggingface-hub ];

      programs.aichat = {
        enable = true;
        settings = {
          model = "spark:GLM-5.3-Flash-NVFP4";
          clients = [
            {
              type = "openai-compatible";
              name = "spark";
              api_base = backend.baseUrl;
              models = lib.mapAttrsToList (name: _: { inherit name; }) backend.models;
            }
          ];
        };
      };
    };
}
