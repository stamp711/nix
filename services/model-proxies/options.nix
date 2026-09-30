{ lib, ... }:
{
  # OpenAI-compatible backends to feed into CLIProxyAPI
  options.modelBackends = lib.mkOption {
    default = { };
    description = "Upstream inference endpoints and the models to expose through proxies.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          baseUrl = lib.mkOption {
            type = lib.types.str;
            description = "Upstream OpenAI-compatible API endpoint.";
          };
          models = lib.mkOption {
            description = "Models to expose, keyed by the model identifier sent in the inference API's `model` field.";
            type = lib.types.attrsOf (
              lib.types.submodule {
                options = {
                  contextWindow = lib.mkOption {
                    type = lib.types.ints.positive;
                    description = "Maximum context length in tokens.";
                  };
                  reasoningEfforts = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    description = "Reasoning effort values accepted by the model.";
                  };
                  inputModalities = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    description = "Input modalities supported by the inference server.";
                  };
                };
              }
            );
          };
        };
      }
    );
  };

  # Proxy deployment modules publish their client-facing endpoints here;
  # personal-codex-config.nix uses them to create profiles with dynamic model discovery.
  options.modelProxies = lib.mkOption {
    default = { };
    description = "Model proxy endpoints exposed to clients.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          baseUrl = lib.mkOption {
            type = lib.types.str;
            description = "OpenAI-compatible API endpoint. Loopback URLs are usable only on the serving host.";
          };
        };
      }
    );
  };
}
