{ self, ... }:
{
  flake.nixosModules.personal =
    { config, lib, ... }:
    let
      psk = self.lib.mkAgeSecret config { rekeyFile = ./psk.age; };
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
      age.secrets = psk.ageSecret;

      my.age-template.files."nm-wifi.env" = {
        placeholders.psk = psk.path;
        content = "PERSONAL_WIFI_PSK=$psk";
      };

      networking.networkmanager.ensureProfiles = {
        environmentFiles = [ env.path ];
        profiles = lib.listToAttrs (map mkProfile ssids);
      };

      systemd.services.NetworkManager-ensure-profiles.restartTriggers = [ env.renderedFileHash ];
    };
}
