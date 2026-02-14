{ self, inputs }:
let
  username = "stamp";
  hostname = "ATT";
  system = "x86_64-linux";
in
{
  description = "Proxy server (KVM VPS)";

  inherit username hostname system;

  nixosConfiguration = self.lib.mkNixos {
    inherit system username;
    modules = [
      self.nixosModules.common.core
      (
        { pkgs, ... }:
        {
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
          imports = [ inputs.disko.nixosModules.disko ];
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
          networking.useNetworkd = true;

          # QEMU guest agent
          services.qemuGuest.enable = true;

          # TODO: Shadowsocks (needs password via opnix)
          # services.shadowsocks = {
          #   enable = true;
          #   passwordFile = ...;
          # };

          # SSH authorized keys
          users.users.${username}.openssh.authorizedKeys.keyFiles = [ inputs.ssh-keys ];
        }
      )
    ];
  };

  deploy = {
    hostname = hostname;
    remoteBuild = false;
  };
}
