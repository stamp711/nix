let
  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
in
{
  description = "Base system: locale, SSH, sudo, nix settings, basic packages";

  nixos =
    {
      self,
      lib,
      pkgs,
      ...
    }:
    {
      # Hack: Extend the users.users submodule to add SSH keys for all normal users.
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

        # Basic system packages
        environment.systemPackages = with pkgs; [
          vim
          git
          curl
          wget
        ];

        # Run unpatched dynamic binaries on NixOS
        programs.nix-ld.enable = true;

        # Nix
        nix.channel.enable = false;
        nix.settings = nixConfig // {
          trusted-users = [
            "root"
            "@wheel"
          ];
          auto-optimise-store = true;
        };

        programs.nh.enable = true;
        programs.nh.flake = "github:stamp711/nix";
      };
    };

  darwin = {
    system.stateVersion = 6;
    determinateNix = {
      enable = true;
      customSettings = nixConfig // {
        trusted-users = [
          "root"
          "@admin"
        ];
        eval-cores = 0; # Enables parallel evaluation
        extra-experimental-features = [ ];
      };
    };
    system.defaults.NSGlobalDomain = {
      KeyRepeat = 1;
      InitialKeyRepeat = 15;
    };
  };

  homeManager =
    { config, pkgs, ... }:
    {
      home.stateVersion = "26.05";

      home.homeDirectory =
        if pkgs.stdenv.isDarwin then "/Users/${config.home.username}" else "/home/${config.home.username}";

      xdg.enable = true;

      programs.home-manager.enable = true;

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        matchBlocks."*".extraOptions.StrictHostKeyChecking = "accept-new";
      };

      # Nix
      nix.package = pkgs.nix;
      nix.settings = nixConfig;

      xdg.configFile."nixpkgs/config.nix".text = ''
        { allowUnfree = true; allowUnfreePredicate = _: true; }
      '';

      programs.nh.enable = true;
      programs.nh.flake = "github:stamp711/nix";
    };
}
