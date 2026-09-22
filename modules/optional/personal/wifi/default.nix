{ self, ... }:
{
  flake.nixosModules.personal =
    { config, lib, ... }:
    let
      psk = self.lib.mkAgeSecret config { rekeyFile = ./psk.env.age; };

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

      networking.networkmanager.ensureProfiles = {
        environmentFiles = [ psk.path ];
        profiles = lib.listToAttrs (map mkProfile ssids);
      };
    };
}
