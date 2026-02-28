{ self, inputs, ... }:
let
  username = "stamp";
  hostname = "GPD";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGTQLBSo+0ienoQG9TV4XyNt3vbN60uS10OD4TUDB1an";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBt5OaxhvkIQJWZ80eX8czcCESykRu8oNlx1UIFiQz0G";
in
{
  flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
    inherit system;
    aspects = [ self.aspectModules.gnome ];
    modules = [
      self.nixosModules.onepassword
      self.nixosModules.audio
      self.nixosModules.networking
      ./hardware.nix
      ./lte.nix
      self.nixosModules.solaar
      (
        { pkgs, ... }:
        {
          networking.hostName = hostname;
          age.rekey.hostPubkey = hostPubkey;

          my.maintenance.autoUpdate = true;
          my.maintenance.autoClean = true;

          my.boot-disk = {
            enable = true;
            layout = "efi-btrfs-luks";
            device = "/dev/nvme0n1";
            swapSize = "32G";
          };
          boot.initrd.availableKernelModules = [
            "nvme"
            "xhci_pci"
            "thunderbolt"
            "usbhid"
          ];
          # Auto-authorize Thunderbolt devices in initrd so USB devices behind
          # Thunderbolt docks/displays work for LUKS unlock.
          boot.initrd.services.udev.rules = ''
            ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
          '';

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

  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system username;
    aspects = [ self.aspectModules.gnome ];
    modules = [
      self.profiles.homeManager.personal
      { age.rekey.hostPubkey = userPubkey; }
      self.homeModules.desktop
    ];
  };

  flake.deploy.nodes.${hostname} = {
    hostname = "GPD.home";
    profiles = {
      home-manager = {
        user = username;
        path =
          inputs.deploy-rs.lib.${system}.activate.home-manager
            self.homeConfigurations."${username}@${hostname}";
      };
      system = {
        user = "root";
        path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${hostname};
      };
    };
  };
}
