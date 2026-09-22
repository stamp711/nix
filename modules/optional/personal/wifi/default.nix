# Wifi PSKs stay in agenix; nm-file-secret-agent serves them to NetworkManager on demand.
{ self, ... }:
{
  flake.nixosModules.personal =
    { config, lib, ... }:
    let
      psk = self.lib.mkAgeSecret config { rekeyFile = ./psk.age; };

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
            psk-flags = 1; # agent-owned
          };
        };
      };

      mkSecretEntry = ssid: {
        matchId = ssid;
        key = "psk";
        file = psk.path;
      };
    in
    {
      age.secrets = psk.ageSecret;

      networking.networkmanager.ensureProfiles = {
        profiles = lib.listToAttrs (map mkProfile ssids);
        secrets.entries = map mkSecretEntry ssids;
      };
    };
}
