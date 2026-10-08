{ self, lib, ... }:
{
  flake.nixosModules.dgx-spark =
    { config, pkgs, ... }:
    let
      imageName = "vllm/vllm-openai";
      finalImageTag = "v0.31.0-aarch64";
      hfDir = "${config.users.users.${config.my.primaryUser}.home}/.cache/huggingface";

      interface =
        config.networking.networkmanager.ensureProfiles.profiles.qsfp0-P0.connection.interface-name;
      getAddress =
        hostConfig:
        lib.head (
          lib.splitString "/" hostConfig.networking.networkmanager.ensureProfiles.profiles.qsfp0-P0.ipv4.address1
        );
    in
    {
      virtualisation.oci-containers.containers.vllm = {
        image = "${imageName}:${finalImageTag}";
        imageFile = pkgs.dockerTools.pullImage {
          inherit imageName finalImageTag;
          imageDigest = "sha256:3f7dd5b777d34d1724456ce71f87385dca288c3bb23029ab27dee358f5d2b971";
          hash = "sha256-AmQCV1xDPuynM28m9RwvgkMwJswhWy7rnX33GQgXCSA=";
        };
        pull = "never";
        networks = [ "host" ];
        devices = [
          "nvidia.com/gpu=all"
          "/dev/infiniband"
        ];
        volumes = [
          "${hfDir}:/hf:ro"
          "/var/cache/vllm:/cache:rw"
        ];
        environment = {
          HOME = "/cache";
          VLLM_HOST_IP = getAddress config;
          NCCL_SOCKET_IFNAME = "=${interface}";
          GLOO_SOCKET_IFNAME = interface;
          # Limit kernel compilation memory while the model is resident.
          MAX_JOBS = "2";
          FLASHINFER_NVCC_THREADS = "1";
          # Bound long-prefill allocations on GB10: https://github.com/vllm-project/vllm/issues/55569
          VLLM_SPARSE_INDEXER_MAX_LOGITS_MB = "64";
        };
        cmd = [
          # TODO: use an HF repo ID with a persistent cache for automatic downloads.
          "/hf/models/nvidia/GLM-5.3-Flash-NVFP4"
          "--tensor-parallel-size=2"
          "--nnodes=2"
          "--master-addr=${getAddress self.nixosConfigurations.spark-abbc.config}"
          "--max-model-len=262144"
          "--max-num-seqs=1"
          "--max-num-batched-tokens=2048"
          "--gpu-memory-utilization=0.85"
          "--kv-cache-dtype=fp8"
          # Avoid synchronized FlashInfer autotuning stalls across the two Sparks.
          # https://github.com/vllm-project/vllm/issues/52291
          "--no-enable-flashinfer-autotune"
          # Avoid the maximum-size video encoder profile during startup.
          ''--limit-mm-per-prompt={"image":2,"video":0}''
        ];
        extraOptions = [
          "--ipc=host" # for shm
          "--ulimit=memlock=-1:-1"
        ];
      };

      my.persistence.directories = [ "/var/cache/vllm" ];

      systemd.services.podman-vllm = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        serviceConfig = {
          # Reuse compiled kernels across service restarts and reboots.
          CacheDirectory = "vllm";
          CacheDirectoryMode = "0700";
        };
      };
    };

  flake.nixosModules.spark-abbc.virtualisation.oci-containers.containers.vllm.cmd = lib.mkAfter [
    "--node-rank=0"
    "--port=8080"
    "--served-model-name=GLM-5.3-Flash-NVFP4"
    "--reasoning-parser=glm45"
    "--enable-auto-tool-choice"
    "--tool-call-parser=glm47"
  ];

  flake.nixosModules.spark-14f3.virtualisation.oci-containers.containers.vllm.cmd = lib.mkAfter [
    "--node-rank=1"
    "--headless"
  ];
}
