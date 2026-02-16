{ self, inputs }:
let
  username = "stamp";
  hostname = "NURO";
  system = "x86_64-linux";
in
{
  description = "Proxy server (KVM VPS)";

  inherit username hostname system;

  deploy = {
    hostname = "proxy-nuro";
    remoteBuild = false;
  };

  nixosConfiguration = self.lib.mkNixos {
    inherit system username;
    modules = [
      self.nixosModules.common.core
      (
        { config, pkgs, ... }:
        {
          imports = [
            inputs.disko.nixosModules.disko
            inputs.agenix.nixosModules.default
            inputs.agenix-rekey.nixosModules.default
          ];

          age.rekey = {
            masterIdentities = [
              {
                identity = "${self}/ssh-age.pub";
                pubkey = self.lib.sshPublicKeys.age;
              }
            ];
            hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB50dHwZLQyKtq7VV9pa9F4QJJtGW0jgJ+RsV/x2IpJI";
            storageMode = "local";
            localStorageDir = "${self}/agenix-rekey/${hostname}";
          };

          environment.systemPackages = [ pkgs._1password-cli ];
          networking.hostName = hostname;

          # KVM/virtio kernel modules
          boot.initrd.availableKernelModules = [
            "virtio_pci"
            "virtio_blk"
            "virtio_net"
            "virtio_scsi"
          ];

          # GRUB bootloader (MBR, device set by disko via EF02 partition)
          boot.loader.grub.enable = true;

          # Disk layout (disko)
          disko.devices.disk.main = {
            device = "/dev/vda";
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                boot = {
                  size = "1M";
                  type = "EF02"; # BIOS boot partition
                };
                root = {
                  size = "100%";
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/";
                  };
                };
              };
            };
          };

          # Network config via provider metadata service
          services.cloud-init.enable = true;
          systemd.services.cloud-config.serviceConfig.SuccessExitStatus = "1";
          systemd.services.cloud-final.serviceConfig.SuccessExitStatus = "1";
          networking.useNetworkd = true;

          # QEMU guest agent
          services.qemuGuest.enable = true;

          # Caddy: reverse proxy to VLESS & VMESS & Trojan
          age.secrets.caddy-config = {
            rekeyFile = ./caddy-config.age;
            owner = "caddy";
            group = "caddy";
          };
          services.caddy = {
            enable = true;
            configFile = config.age.secrets.caddy-config.path;
          };
          systemd.services.caddy.restartTriggers = [ config.age.secrets.caddy-config.rekeyFile ];

          # VLESS
          age.secrets.xray-config.rekeyFile = ./xray-config.json.age;
          services.xray = {
            enable = true;
            settingsFile = config.age.secrets.xray-config.path;
          };
          systemd.services.xray.restartTriggers = [ config.age.secrets.xray-config.rekeyFile ];

          # Snell
          age.secrets.snell-config.rekeyFile = ./snell.conf.age;
          systemd.services.snell.restartTriggers = [ config.age.secrets.snell-config.rekeyFile ];
          systemd.services.snell = {
            description = "Snell Server";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              ExecStart = "${pkgs.snell}/bin/snell-server -c %d/config";
              LoadCredential = "config:${config.age.secrets.snell-config.path}";
              DynamicUser = true;
              NoNewPrivileges = true;
            };
          };

          networking.firewall.allowedTCPPorts = [
            443
            28799
          ];

          # SSH authorized keys
          users.users.${username}.openssh.authorizedKeys.keys = [
            self.lib.sshPublicKeys.apricity
            self.lib.sshPublicKeys.surge
          ];
        }
      )
    ];
  };
}
