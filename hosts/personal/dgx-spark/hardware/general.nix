{ lib, self, ... }:
{
  flake.nixosModules.dgx-spark =
    { config, pkgs, ... }:
    {
      imports = [ self.nixosModules.dgx-spark-mlnx-hotplug ];

      boot.kernelPackages = pkgs.linuxPackagesFor pkgs.my.linux_nvidia;

      # Enable autonomous CPU performance selection on GB10.
      boot.kernelParams = [ "cppc_cpufreq.auto_sel_mode=1" ];

      services.xserver.videoDrivers = [ "nvidia" ];
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
          modesetting.enable = true;
          package = lib.overrideExisting nvidiaPackage {
            open = scrubKernelDevRefs nvidiaPackage.open;
            mod = scrubKernelDevRefs nvidiaPackage.mod;
          };
        };

      services.fwupd.enable = true;
    };
}
