{ self, ... }:
let
  username = "stamp";
  hostname = "NUC";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIClC3VLrypgdZbvJPhufSe6BeWcijyTrnl4JqBs/r566";
  userPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDbNYaZnOCmlfKtRpPEq12Ot3iaVjq0AFj7vsB3DcjQ+";
in
{
  description = "NUC13RNGi9";
  inherit username hostname system;

  deploy = {
    hostname = "NUC.home";
    remoteBuild = true;
  };

  nixosConfiguration = self.lib.mkNixos {
    inherit system;
    modules = [
      self.nixosModules.common.audio
      self.nixosModules.common.networking
      ./hardware.nix
      ./vm.nix
      self.nixosModules.desktop.gnome
      self.nixosModules.desktop.solaar
      (
        { pkgs, ... }:
        {
          networking.hostName = hostname;
          age.rekey.hostPubkey = hostPubkey;

          my.nixos-maintenance.autoUpdate = true;
          my.nixos-maintenance.autoClean = true;

          security.tpm2.enable = true;

          # Always-on desktop - disable all sleep states
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
            ];
          };

          specialisation.desktop.configuration = {
            system.nixos.tags = [ "desktop" ];
            my.win11-vm.enable = false;
          };

          specialisation.gaming.configuration = {
            system.nixos.tags = [ "steam" ];
            my.win11-vm.enable = false;
            programs.gamemode.enable = true;
            services.xserver.videoDrivers = [ "nvidia" ];
            hardware.nvidia.modesetting.enable = true;
            hardware.nvidia.open = true;
            services.displayManager.autoLogin.enable = true;
            services.displayManager.autoLogin.user = username;
            services.displayManager.defaultSession = "steam";
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
