{
  description = "KVM VPS proxy server (Caddy + Xray + Snell)";

  module =
    { self, ... }:
    {
      imports = [
        self.nixosModules.common.allow-cloudflare-443
        self.nixosModules.common.fail2ban
      ];

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

      my.nixos-maintenance.autoUpdate = true;
      my.nixos-maintenance.autoClean = true;
    };
}
