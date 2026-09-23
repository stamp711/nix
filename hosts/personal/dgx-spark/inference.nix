# llama-swap in front of llama.cpp. Fetch weights once with hfdownloader:
#   hfdownloader download unsloth/Qwen3.8-Flash-Next-GGUF -F UD-Q4_K_XL,mtp-Qwen3.8-Flash-Next-shared-Q8_0.gguf -E imatrix --verify sha256
#   hfdownloader download unsloth/Qwen3.6-35B-A3B-GGUF -F UD-Q6_K_XL -E imatrix,mmproj --verify sha256
{ lib, ... }:
{
  flake.nixosModules.dgx-spark =
    { config, pkgs, ... }:
    let
      hf = "${config.users.users.${config.my.primaryUser}.home}/.cache/huggingface";
      models = "${hf}/models"; # hfdownloader's <owner>/<repo> tree, symlinks into hf/hub
      # danielhanchen/llama.cpp qwen4exp/mtp: MTP drafting for Qwen3.8-Flash-Next,
      # pending ggml-org/llama.cpp#28243. Same web UI lockfile as the nixpkgs release.
      llama-cpp = pkgs.llama-cpp-cuda.overrideAttrs {
        version = "0-unstable-2026-09-02";
        src = pkgs.fetchFromGitHub {
          owner = "danielhanchen";
          repo = "llama.cpp";
          rev = "2857e51143bd88ec6fc0246246f42a5d0394d98a";
          hash = "sha256-0GK4zWRuQhMOE4GXCjIVx0hOvSzU9M1c81yCptEbaqU=";
        };
      };
      # `${PORT}` is filled in by llama-swap. `--fit` conflicts with MTP drafting.
      server = "${lib.getExe' llama-cpp "llama-server"} --port \${PORT} -ngl 999 -fa on --jinja --no-webui --fit off -t 20";
    in
    {
      services.llama-swap = {
        enable = true;
        settings = {
          healthCheckTimeout = 600; # cold load of ~100 GiB from NVMe
          models = {
            # 180B MoE, 6B active. The 51B n-gram table (`per_layer_token_embd`) is a
            # lookup read ~2.5 KB/token: keep it out of CUDA-pinned memory, mmap'd from
            # NVMe, which frees ~29 GiB for KV. `--no-op-offload` stops ggml copying it
            # to the GPU for batched ops.
            "qwen3.8-flash-next" = {
              aliases = [ "default" ];
              cmd = "${server} -m ${models}/unsloth/Qwen3.8-Flash-Next-GGUF/UD-Q4_K_XL/Qwen3.8-Flash-Next-UD-Q4_K_XL-00001-of-00004.gguf -md ${models}/unsloth/Qwen3.8-Flash-Next-GGUF/MTP/mtp-Qwen3.8-Flash-Next-shared-Q8_0.gguf --spec-type draft-mtp --spec-draft-n-max 4 -ot per_layer_token_embd=CPU --no-op-offload -c 262144 -ctk q8_0 -ctv q8_0";
            };
            "qwen3.6-35b-a3b" = {
              aliases = [ "fast" ];
              cmd = "${server} -m ${models}/unsloth/Qwen3.6-35B-A3B-GGUF/Qwen3.6-35B-A3B-UD-Q6_K_XL.gguf -c 131072";
            };
          };
        };
      };
      # Upstream hides /home from the unit; expose only the HF cache, read-only.
      systemd.services.llama-swap.serviceConfig = {
        ProtectHome = lib.mkForce "tmpfs";
        BindReadOnlyPaths = [ hf ];
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
    };
}
