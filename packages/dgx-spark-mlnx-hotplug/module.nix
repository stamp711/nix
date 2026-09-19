# Enable the packaged helper. Requires mtk-pcie-hotplug from the NVIDIA kernel.
{
  flake.nixosModules.dgx-spark-mlnx-hotplug =
    { pkgs, ... }:
    {
      boot.kernelModules = [ "mtk-pcie-hotplug" ];
      services.udev.packages = [ pkgs.my.dgx-spark-mlnx-hotplug ];

      # The handler enables hotplug only when this marker exists.
      environment.etc."nvidia/cx7-hotplug-enabled".text = ''
        # Enable ConnectX-7 cable hotplug and power management.
      '';
    };
}
