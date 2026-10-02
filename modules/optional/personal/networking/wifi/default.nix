{ self, ... }:
{
  flake.nixosModules.personal =
    { config, lib, ... }:
    let
      psk = self.lib.mkAgeSecret config { rekeyFile = ./psk.age; };
      pskGL = self.lib.mkAgeSecret config { rekeyFile = ./psk-gl.age; };
      env = config.my.age-template.files."nm-wifi.env";

      ssids = [
        "Aprixnet"
        "Liu’s iPhone"
        "Liu’s Work iPhone"
      ];

      mkProfile = ssid: {
        name = ssid;
        value = {
          connection = {
            id = ssid;
            type = "wifi";
          };
          wifi.ssid = ssid;
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$PERSONAL_WIFI_PSK";
          };
        };
      };
    in
    {
      age.secrets = self.lib.mergeDisjoint [
        psk.ageSecret
        pskGL.ageSecret
      ];

      my.age-template.files."nm-wifi.env" = {
        placeholders.psk = psk.path;
        placeholders.pskGL = pskGL.path;
        content = ''
          PERSONAL_WIFI_PSK=$psk
          PERSONAL_WIFI_GL_PSK=$pskGL
        '';
      };

      networking.networkmanager.ensureProfiles = {
        environmentFiles = [ env.path ];
        profiles = self.lib.mergeDisjoint [
          (lib.listToAttrs (map mkProfile ssids))
          {
            "Aprixnet.GL" = lib.recursiveUpdate (mkProfile "Aprixnet.GL").value {
              wifi-security.psk = "$PERSONAL_WIFI_GL_PSK";
            };
          }
        ];
      };

      systemd.services.NetworkManager-ensure-profiles.restartTriggers = [ env.renderedFileHash ];
    };
}
