{
  description = "Base NixOS system: nix, locale, SSH, sudo";

  module =
    {
      self,
      lib,
      pkgs,
      ...
    }:
    {
      # Extend the users.users submodule to add SSH keys for all normal users.
      # Uses submodule merging to avoid infinite recursion with config.users.users.
      options.users.users = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { config, ... }:
            {
              config.openssh.authorizedKeys.keys = lib.mkIf config.isNormalUser [
                self.lib.sshPublicKeys.apricity
              ];
            }
          )
        );
      };

      config = {
        system.stateVersion = "26.05";

        # Nix
        programs.nh = {
          enable = true;
          clean = {
            enable = true;
            extraArgs = "--keep-since 30d --keep 3";
          };
        };
        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [
            "root"
            "@wheel"
          ];
        };

        # Locale
        time.timeZone = "Asia/Shanghai";
        i18n.defaultLocale = "en_US.UTF-8";

        # SSH
        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            PermitRootLogin = "no";
          };
        };

        # Sudo
        security.sudo.wheelNeedsPassword = false;

        # Terminfo for modern terminal emulators (ghostty, kitty, foot, etc.)
        environment.enableAllTerminfo = true;

        # Basic system packages
        environment.systemPackages = with pkgs; [
          vim
          git
          curl
          wget
        ];
      };
    };
}
