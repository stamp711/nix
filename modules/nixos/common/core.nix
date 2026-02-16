{
  description = "Base NixOS system: nix, locale, SSH, sudo";

  module =
    { pkgs, ... }:
    {
      system.stateVersion = "26.05";

      # Nix
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

      # Basic system packages
      environment.systemPackages = with pkgs; [
        vim
        git
        curl
        wget
      ];
    };
}
