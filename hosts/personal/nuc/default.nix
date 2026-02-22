{ self, ... }:
let
  username = "stamp";
  hostname = "NUC";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClC3VLrypgdZbvJPhufSe6BeWcijyTrnl4JqBs/r566";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDbNYaZnOCmlfKtRpPEq12Ot3iaVjq0AFj7vsB3DcjQ+";
in
{
  description = "NUC13 desktop with VFIO GPU passthrough";
  inherit username hostname system;

  deploy = {
    hostname = "NUC.home";
    remoteBuild = true;
  };

  nixosConfiguration = self.lib.mkNixos {
    inherit system;
    modules = [
      self.nixosModules.common.core
      self.nixosModules.common.agenix-rekey
      self.nixosModules.common.audio
      self.nixosModules.common.networking
      ./hardware.nix
      ./vm.nix
      self.nixosModules.desktop.gnome
      self.nixosModules.boot-disk.efi-btrfs-luks
      (
        { pkgs, ... }:
        {
          networking.hostName = hostname;
          age.rekey.hostPubkey = hostPubkey;

          boot-disk.device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_1TB_S6Z1NJ0W395410E";
          boot-disk.swapSize = "16G";
          boot.initrd.availableKernelModules = [
            "nvme"
            "xhci_pci"
            "usbhid"
            "ahci"
            "thunderbolt"
            "tpm_crb"
          ];
          security.tpm2.enable = true;
          boot.kernelModules = [ "kvm-intel" ];

          # Always-on desktop — disable all sleep states
          systemd.targets.sleep.enable = false;
          systemd.targets.suspend.enable = false;
          systemd.targets.hibernate.enable = false;
          systemd.targets.hybrid-sleep.enable = false;
          services.displayManager.gdm.autoSuspend = false;

          programs.zsh.enable = true;
          users.defaultUserShell = pkgs.zsh;

          programs.steam.enable = true;
          programs.steam.gamescopeSession.enable = true;

          # Primary user
          users.users.${username} = {
            uid = 1000;
            isNormalUser = true;
            extraGroups = [
              "wheel"
              "networkmanager"
              "libvirtd"
            ];
          };
        }
      )
    ];
  };

  homeConfiguration = self.lib.mkHome {
    inherit system username;
    modules = [
      self.homeProfiles.personal
      { age.rekey.hostPubkey = userPubkey; }
    ]
    ++ self.homeModules.desktop._all;
  };
}
