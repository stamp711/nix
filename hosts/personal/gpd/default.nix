{ self, ... }:
let
  username = "stamp";
  hostname = "GPD";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTQLBSo+0ienoQG9TV4XyNt3vbN60uS10OD4TUDB1an";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBt5OaxhvkIQJWZ80eX8czcCESykRu8oNlx1UIFiQz0G";
in
{
  description = "GPD Pocket 4";
  inherit username hostname system;

  deploy = {
    hostname = "GPD.home";
  };

  nixosConfiguration = self.lib.mkNixos {
    inherit system;
    modules = [
      self.nixosModules.common.core
      self.nixosModules.common.onepassword
      self.nixosModules.common.agenix-rekey
      self.nixosModules.common.audio
      self.nixosModules.common.networking
      ./hardware.nix
      ./lte.nix
      self.nixosModules.desktop.gnome
      self.nixosModules.boot-disk.efi-btrfs-luks
      (
        { pkgs, ... }:
        {
          networking.hostName = hostname;
          age.rekey.hostPubkey = hostPubkey;

          boot-disk.device = "/dev/nvme0n1";
          boot-disk.swapSize = "32G";
          boot.initrd.availableKernelModules = [
            "nvme"
            "xhci_pci"
            "thunderbolt"
            "usbhid" # external USB keyboard for LUKS passphrase
          ];

          programs.zsh.enable = true;
          users.defaultUserShell = pkgs.zsh;

          # Primary user
          users.users.${username} = {
            uid = 1000;
            isNormalUser = true;
            extraGroups = [
              "wheel"
              "networkmanager"
            ];
          };

          programs.steam.enable = true;
          programs.steam.gamescopeSession.enable = true;
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
