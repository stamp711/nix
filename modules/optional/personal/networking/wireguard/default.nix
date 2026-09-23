# WireGuard through NetworkManager; A dispatcher connects it whenever the active wifi is not in a whitelist.
{ self, lib, ... }:
let
  wg = {
    name = "wg-home";
    peerPublicKey = "082oqV6W620CaAbk4gGSMAquXVIH0UE37TIB3l6rHTU=";
    addrPrefix = {
      v4 = "10.0.254.";
      v6 = "fd10:0:254::";
    };
    dns = {
      v4 = "198.18.0.2";
      v6 = "fd00:6152::2";
    };
  };
  noTunnelWifi = [ "Aprixnet" ];
in
{
  flake.nixosModules.personal =
    { config, pkgs, ... }:
    {
      options.personal.wireguard = {
        enable = lib.mkEnableOption "the personal wireguard tunnel";
        addrSuffix = lib.mkOption {
          type = lib.types.int;
          example = 10;
          description = "This device inside the tunnel: ${wg.addrPrefix.v4}N, and ${wg.addrPrefix.v6} with N in hex.";
        };
        privateKeyFile = lib.mkOption {
          type = lib.types.str;
          description = "Decrypted file holding this device's private key.";
        };
      };

      config =
        let
          cfg = config.personal.wireguard;
          ageSecretEndpoint = self.lib.mkAgeSecret config { rekeyFile = ./endpoint.age; };
          ageTemplateFileEnv = config.my.age-template.files."nm-wireguard.env";
          addrSuffix = {
            dec = toString cfg.addrSuffix;
            hex = lib.toLower (lib.toHexString cfg.addrSuffix);
          };
        in
        lib.mkIf cfg.enable {
          age.secrets = ageSecretEndpoint.ageSecret;

          my.age-template.files."nm-wireguard.env" = {
            placeholders = {
              endpoint = ageSecretEndpoint.path;
              key = cfg.privateKeyFile; # per host config
            };
            content = ''
              PERSONAL_WG_ENDPOINT=$endpoint
              PERSONAL_WG_PRIVATE_KEY=$key
            '';
          };

          networking.networkmanager = {
            ensureProfiles = {
              environmentFiles = [ ageTemplateFileEnv.path ];
              profiles.${wg.name} = {
                connection = {
                  id = wg.name;
                  type = "wireguard";
                  interface-name = wg.name;
                  autoconnect = false; # the dispatcher decides
                };
                wireguard.private-key = "$PERSONAL_WG_PRIVATE_KEY";
                "wireguard-peer.${wg.peerPublicKey}" = {
                  endpoint = "$PERSONAL_WG_ENDPOINT";
                  allowed-ips = "0.0.0.0/0;::/0;";
                };
                ipv4 = {
                  method = "manual";
                  address1 = "${wg.addrPrefix.v4}${addrSuffix.dec}/32";
                  dns = "${wg.dns.v4};";
                  dns-priority = -10; # negative: exclusive, so nothing leaks to the local resolver
                };
                ipv6 = {
                  method = "manual";
                  address1 = "${wg.addrPrefix.v6}${addrSuffix.hex}/128";
                  dns = "${wg.dns.v6};";
                  dns-priority = -10;
                };
              };
            };

            # nmcli from a dispatcher can deadlock NM, so defer to a systemd unit.
            dispatcherScripts = [
              {
                type = "basic";
                source = pkgs.writeShellScript "wg-dispatch" ''
                  case "$1" in ${wg.name}) exit 0 ;; esac
                  case "$2" in up | down) exec ${lib.getExe' config.systemd.package "systemctl"} start --no-block wg-toggle.service ;; esac
                '';
              }
            ];
          };

          systemd.services.NetworkManager-ensure-profiles.restartTriggers = [
            ageTemplateFileEnv.renderedFileHash
          ];

          systemd.services.wg-toggle = {
            serviceConfig.Type = "oneshot";
            script =
              let
                nmcli = lib.getExe' pkgs.networkmanager "nmcli";
              in
              ''
                ssid=$(${nmcli} -t -f TYPE,NAME connection show --active | sed -n 's/^802-11-wireless://p' | head -n1)
                case "$ssid" in
                  "" | ${lib.concatMapStringsSep " | " lib.escapeShellArg noTunnelWifi}) want=down ;;
                  *) want=up ;;
                esac
                ${nmcli} -t -f NAME connection show --active | grep -qx ${wg.name} && have=up || have=down
                [ "$want" = "$have" ] || ${nmcli} connection "$want" ${wg.name}
              '';
          };
        };
    };
}
