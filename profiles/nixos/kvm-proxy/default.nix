{
  description = "KVM VPS proxy server (Caddy + Xray + Snell)";

  module =
    { self, ... }:
    {
      imports = [
        self.nixosModules.common.core
        self.nixosModules.common.agenix-rekey
        self.nixosModules.services.xray-proxy
        self.nixosModules.services.snell
        self.nixosModules.common.allow-cloudflare-443
        self.nixosModules.common.fail2ban
        self.nixosModules.boot-disk.mbr-ext4
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

      boot-disk.device = "/dev/vda";

      # Proxy services
      services.xray-proxy = {
        enable = true;
        secretEnvFiles = [ ./xray-proxy.env.age ];
      };
      services.snell = {
        enable = true;
        openFirewall = true;
        port = 28799;
        pskSecretFile = ./snell-psk.age;
      };
    };
}
