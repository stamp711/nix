{ self, ... }:
{
  flake.nixosModules.surface =
    { config, pkgs, ... }:
    let
      adapter = "/var/lib/bluetooth/80:E4:BA:2C:6F:18";
      keyboard = self.lib.mkAgeSecret config {
        rekeyFile = ./keyboard-info.age;
      };
      pen = self.lib.mkAgeSecret config {
        rekeyFile = ./pen-info.age;
      };
      installDevice = address: secret: ''
        ${pkgs.coreutils}/bin/install -d -m 0700 \
          -o root -g root ${adapter}/${address}
        ${pkgs.coreutils}/bin/install -m 0600 \
          -o root -g root ${secret.path} ${adapter}/${address}/info
      '';
    in
    {
      services.keyd.keyboards.surface-flex = {
        # Swap left Alt and left Windows on the Surface Flex Keyboard.
        ids = [
          "045e:0c8b:b040ea89" # Attached
          "045e:0c7a:3ff4f52e" # Bluetooth
        ];
        settings.main = {
          capslock = "leftcontrol";
          leftalt = "layer(meta)";
          leftmeta = "layer(alt)";
        };
      };

      age.secrets = self.lib.mergeDisjoint [
        keyboard.ageSecret
        pen.ageSecret
      ];

      # Restore Windows pairing keys while bluetoothd is stopped; BlueZ can
      # update these regular files with discovered state after startup.
      systemd.services.bluetooth.preStart = ''
        ${installDevice "F4:D7:F0:D0:91:D3" keyboard}
        ${installDevice "FB:5A:56:03:1E:E8" pen}
      '';
    };
}
