{
  flake.nixosModules.dgx-spark =
    { config, pkgs, ... }:
    let
      port = 8080;
      imageName = "vllm/vllm-openai";
      finalImageTag = "qwen38";
      hfDir = "${config.users.users.${config.my.primaryUser}.home}/.cache/huggingface";
    in
    {
      virtualisation.oci-containers.containers.vllm = {
        image = "${imageName}:${finalImageTag}";
        imageFile = pkgs.dockerTools.pullImage {
          inherit imageName finalImageTag;
          imageDigest = "sha256:4a2f33a884222f7049b983263ad9976f89452bb81affecf5b67d89ad35c1bc31";
          hash = "sha256-XDIsegL87ZxuXThdZJ19suomm28QH/e8A3+io2utviQ=";
          os = "linux";
          arch = "arm64";
        };
        pull = "never";
        ports = [ "${toString port}:${toString port}" ];
        devices = [ "nvidia.com/gpu=all" ];
        volumes = [
          "${hfDir}:/hf:ro"
          "/var/cache/vllm:/cache:rw"
        ];
        environment.HOME = "/cache";
        # The model's native context is 262144 tokens.
        cmd = [
          # TODO: use an HF repo ID with a persistent cache for automatic downloads.
          "/hf/models/nvidia/Qwen3.8-27B-NVFP4"
          "--served-model-name=Qwen3.8-27B-NVFP4"
          "--port=${toString port}"
          "--max-num-seqs=1"
          "--gpu-memory-utilization=0.7"
          "--kv-cache-dtype=fp8"
          "--no-enable-prefix-caching"
          "--reasoning-parser=qwen3"
          "--enable-auto-tool-choice"
          "--tool-call-parser=qwen3_xml"
        ];
        extraOptions = [
          "--ipc=host" # for shm
          "--ulimit=memlock=-1:-1"
        ];
      };

      my.persistence.directories = [ "/var/cache/vllm" ];

      systemd.services.podman-vllm.serviceConfig = {
        # Reuse compiled kernels across service restarts and reboots.
        CacheDirectory = "vllm";
        CacheDirectoryMode = "0700";
      };
    };
}
