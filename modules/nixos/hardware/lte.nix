{
  description = "4G LTE modem support (Quectel EC25)";

  module =
    { pkgs, ... }:
    {
      # ModemManager with FCC unlock for Quectel (vendor 2c7c)
      networking.modemmanager = {
        enable = true;
        fccUnlockScripts = [
          {
            id = "2c7c";
            path = "${pkgs.modemmanager}/share/ModemManager/fcc-unlock.available.d/2c7c";
          }
        ];
      };

      # Kernel modules for USB modem
      boot.kernelModules = [
        "option"
        "cdc_mbim"
        "qmi_wwan"
      ];

      # udev rule for Quectel EC25 (2c7c:0125)
      # Future: RM520N 5G module uses 2c7c:0801
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2c7c", ATTR{idProduct}=="0125", RUN+="${pkgs.modemmanager}/bin/mmcli -S"
      '';

      # CLI tools
      environment.systemPackages = with pkgs; [
        modemmanager
        libmbim
        libqmi
      ];
    };
}
