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
        nix.channel.enable = false;
        nix.settings = self.lib.nixConfig // {
          trusted-users = [
            "root"
            "@wheel"
          ];
          auto-optimise-store = true;
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

        # Enable but no firewall setting - not exposed on proxy servers
        services.eternal-terminal.enable = true;

        # Sudo
        security.sudo.wheelNeedsPassword = false;

        # Terminfo for modern terminal emulators (ghostty, kitty, foot, etc.)
        environment.enableAllTerminfo = true;

        # nh (nix helper)
        programs.nh.enable = true;
        programs.nh.flake = "github:stamp711/nix";

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
