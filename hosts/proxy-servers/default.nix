{
  self,
  inputs,
  lib,
  ...
}:
let
  system = "x86_64-linux";
  mkProxy = hostname: hostPubkey: {
    flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
      inherit system;
      modules = [
        self.profiles.nixos.headless
        self.nixosModules.allow-cloudflare-443
        self.nixosModules.fail2ban
        {
          my.primaryUser = "stamp";
          networking.hostName = hostname;
          age.rekey.hostPubkey = hostPubkey;

          # KVM/virtio kernel modules
          boot.initrd.availableKernelModules = [
            "virtio_pci"
            "virtio_blk"
            "virtio_net"
            "virtio_scsi"
          ];

          # Network config via provider metadata service
          services.cloud-init.enable = true;
          systemd.services.cloud-config.serviceConfig.SuccessExitStatus = "1";
          systemd.services.cloud-final.serviceConfig.SuccessExitStatus = "1";
          networking.useNetworkd = true;

          # QEMU guest agent
          services.qemuGuest.enable = true;

          my.boot-disk = {
            enable = true;
            layout = "mbr-ext4";
            device = "/dev/vda";
          };

          networking.firewall.enable = true;
          services.openssh.ports = [ 50022 ];

          # Proxy services
          my.xray-proxy = {
            enable = true;
            secretEnvFiles = [ ./xray-proxy.env.age ];
          };
          my.snell = {
            enable = true;
            openFirewall = true;
            port = 28799;
            pskSecretFile = ./snell-psk.age;
          };

          my.maintenance.cleanDates = "daily";
          my.maintenance.keepSince = "0h";
          my.maintenance.keepGenerations = 1;
        }
      ];
    };
    flake.deploy.nodes.${hostname} = {
      hostname = "proxy-${lib.toLower hostname}";
      remoteBuild = false;
      profiles.system = {
        user = "root";
        path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${hostname};
      };
    };
  };
in
lib.mkMerge [
  (mkProxy "VIA" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG21GuCJYYrjfsyvKO2LeQVTS4zYkPDEXf4JVpWoujdY")
  (mkProxy "NURO" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB50dHwZLQyKtq7VV9pa9F4QJJtGW0jgJ+RsV/x2IpJI")
]
