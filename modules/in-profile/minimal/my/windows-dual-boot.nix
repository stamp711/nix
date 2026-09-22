# Windows entry in the systemd-boot menu, for machines that dual-boot it.
{ lib, ... }:
{
  flake.nixosModules.my =
    { config, pkgs, ... }:
    let
      cfg = config.my.windows-dual-boot;
      entryKey = "11"; # Keys the systemd-boot entry: file windows_11.conf, title "Windows 11".
    in
    {
      options.my.windows-dual-boot = {
        enable = lib.mkEnableOption "a Windows entry in the systemd-boot menu";

        efiDeviceHandle = lib.mkOption {
          type = lib.types.str;
          example = "HD0b";
          description = ''
            EDK2 shell handle of the ESP holding the Windows bootloader, shaped
            `HD<controller rank><partition letter>`. Read it off the machine by
            enabling {option}`boot.loader.systemd-boot.edk2-uefi-shell.enable`,
            booting the shell entry and running `map -c`.
          '';
        };

        deactivateNvramEntry = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Mark the Windows Boot Manager NVRAM entry inactive on each boot, so
            Windows can't promote itself ahead of systemd-boot in the boot order.
            https://www.yhi.moe/blog/en/preventing-windows-from-modifying-your-uefi-boot-sequence
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        boot.loader.systemd-boot.windows.${entryKey} = {
          inherit (cfg) efiDeviceHandle;
        };

        environment.systemPackages = [
          (pkgs.writeShellScriptBin "reboot-windows" ''
            exec systemctl reboot --boot-loader-entry=windows_${entryKey}.conf
          '')
        ];

        systemd.services = lib.mkIf cfg.deactivateNvramEntry {
          deactivate-windows-boot-entry = {
            description = "Deactivate Windows Boot Manager NVRAM entry";
            wantedBy = [ "multi-user.target" ];
            path = [ pkgs.efibootmgr ];
            serviceConfig.Type = "oneshot";
            script = ''
              efibootmgr | grep -E '^Boot[0-9A-Fa-f]{4}\* Windows Boot Manager' | while read -r line; do
                num="''${line:4:4}"
                echo "Deactivating: $line"
                efibootmgr --bootnum "$num" --inactive
              done
            '';
          };
        };
      };
    };
}
