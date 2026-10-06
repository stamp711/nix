{ lib, self, ... }:
{
  flake.nixosModules.dgx-spark =
    { config, pkgs, ... }:
    {
      imports = [ self.nixosModules.dgx-spark-mlnx-hotplug ];

      boot.kernelPackages = pkgs.linuxPackagesFor pkgs.my.linux_nvidia;

      # Enable autonomous CPU performance selection on GB10.
      boot.kernelParams = [ "cppc_cpufreq.auto_sel_mode=1" ];
      boot.kernelModules = [
        "mlx5_ib"
        "ib_uverbs"
      ];

      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.graphics.enable = true; # /run/opengl-driver/lib/libcuda.so.1
      hardware.nvidia =
        let
          # NVIDIA modules built against linux_nvidia retain kernel.dev paths.
          # Remove these references so nixpkgs' module output check accepts them.
          # Workaround from https://github.com/graham33/nixos-dgx-spark/blob/main/modules/dgx-spark.nix
          scrubKernelDevRefs =
            drv:
            drv.overrideAttrs (old: {
              postFixup = (old.postFixup or "") + ''
                if [ -d "$out/lib/modules" ]; then
                  find "$out/lib/modules" -name '*.ko' -print0 \
                    | xargs -0 -r ${pkgs.removeReferencesTo}/bin/remove-references-to \
                        -t ${config.boot.kernelPackages.kernel.dev}
                fi
              '';
            });
          nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.production;
        in
        {
          open = true;
          nvidiaPersistenced = true;
          package = lib.overrideExisting nvidiaPackage {
            open = scrubKernelDevRefs nvidiaPackage.open;
            mod = scrubKernelDevRefs nvidiaPackage.mod;
          };
        };

      boot.extraModprobeConfig = "options nvidia NVreg_RestrictProfilingToAdminUsers=0"; # for nsys

      hardware.nvidia-container-toolkit.enable = true;

      # OCI units invoke Podman directly, so order every container after CDI generation.
      systemd.services = lib.mapAttrs' (
        _: container:
        lib.nameValuePair container.serviceName {
          requires = [ "nvidia-container-toolkit-cdi-generator.service" ];
          after = [ "nvidia-container-toolkit-cdi-generator.service" ];
        }
      ) config.virtualisation.oci-containers.containers;

      services.fwupd.enable = true;

      environment.systemPackages = [
        pkgs.rdma-core
        pkgs.nvtopPackages.nvidia
        pkgs.cudaPackages.nsight_systems
        pkgs.cudaPackages.nsight_compute
      ];
    };
}
