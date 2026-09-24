# llama-swap in front of llama.cpp.
{ lib, ... }:
let
  # GGUF paths are relative to hfdownloader's <owner>/<repo> tree.
  #   hfdownloader download unsloth/Qwen3.8-Flash-Next-GGUF -F UD-Q4_K_XL,mtp-Qwen3.8-Flash-Next-shared-Q8_0.gguf -E imatrix --verify sha256
  #   hfdownloader download unsloth/Qwen3.6-35B-A3B-GGUF -F UD-Q6_K_XL -E imatrix,mmproj --verify sha256
  models = {
    "Qwen3.8-Flash-Next-UD-Q4_K_XL" = {
      model = "unsloth/Qwen3.8-Flash-Next-GGUF/UD-Q4_K_XL/Qwen3.8-Flash-Next-UD-Q4_K_XL-00001-of-00004.gguf";
      draft = "unsloth/Qwen3.8-Flash-Next-GGUF/MTP/mtp-Qwen3.8-Flash-Next-shared-Q8_0.gguf";
      args = [
        "--spec-type draft-mtp --spec-draft-n-max 4"
        "--ctx-size 262144 --cache-type-k q8_0 --cache-type-v q8_0"
        "--batch-size 2048 --ubatch-size 2048" # ubatch-size default 2048; 398 -> 528 tok/s prefill at 34K, +6.5 GB
      ];
    };
    "Qwen3.6-35B-A3B-UD-Q6_K_XL" = {
      model = "unsloth/Qwen3.6-35B-A3B-GGUF/Qwen3.6-35B-A3B-UD-Q6_K_XL.gguf";
      args = [ "--ctx-size 131072" ];
    };
  };
  default = "Qwen3.8-Flash-Next-UD-Q4_K_XL";
in
{

  flake.nixosModules.dgx-spark =
    { config, pkgs, ... }:
    let
      hfDir = "${config.users.users.${config.my.primaryUser}.home}/.cache/huggingface";
      modelsDir = "${hfDir}/models"; # symlinks into hf/hub

      # danielhanchen/llama.cpp qwen4exp/mtp: MTP drafting for Qwen3.8-Flash-Next,
      # pending ggml-org/llama.cpp#28243.
      llama-cpp = pkgs.llama-cpp-cuda.overrideAttrs {
        version = "0-unstable-2026-09-02";
        src = pkgs.fetchFromGitHub {
          owner = "danielhanchen";
          repo = "llama.cpp";
          rev = "2857e51143bd88ec6fc0246246f42a5d0394d98a";
          hash = "sha256-0GK4zWRuQhMOE4GXCjIVx0hOvSzU9M1c81yCptEbaqU=";
        };
      };
    in
    {
      services.llama-swap =
        let
          # `${PORT}` is filled in by llama-swap. `--fit` conflicts with MTP drafting.
          server = lib.concatStringsSep " " [
            (lib.getExe' llama-cpp "llama-server")
            "--port \${PORT} --n-gpu-layers 999 --flash-attn on --jinja --no-webui --fit off --threads 20"
          ];
        in
        {
          enable = true;
          settings = {
            healthCheckTimeout = 600; # cold load of ~100 GiB from NVMe
            models = lib.mapAttrs (_: m: {
              cmd = lib.concatStringsSep " " (
                [
                  server
                  "--model ${modelsDir}/${m.model}"
                ]
                ++ lib.optional (m ? draft) "--model-draft ${modelsDir}/${m.draft}"
                ++ m.args
              );
            }) models;
          };
        };
      # Upstream hides /home from the unit; expose only the HF cache, read-only.
      # NOTE: need to restart this service if dir gets a new inode.
      systemd.services.llama-swap = {
        path = [ config.hardware.nvidia.package.bin ]; # nvidia-smi
        serviceConfig = {
          ProtectHome = lib.mkForce "tmpfs";
          BindReadOnlyPaths = [ hfDir ];
        };
      };

      environment.systemPackages = [ llama-cpp ];
    };

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
          model = "spark:${default}";
          clients = [
            {
              type = "openai-compatible";
              name = "spark";
              api_base = "http://127.0.0.1:8080/v1";
              models = map (name: { inherit name; }) (builtins.attrNames models);
            }
          ];
        };
      };
    };

}
