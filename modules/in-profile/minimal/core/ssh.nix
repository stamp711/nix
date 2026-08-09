{
  flake.nixosModules.core =
    { config, ... }:
    {
      config = {
        # SSH server
        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            PermitRootLogin = "no";
          };
          # An ephemeral root wipes /etc every boot.
          hostKeys =
            let
              dir = if config.my.persistence.enable then "${config.my.persistence.path}/etc/ssh" else "/etc/ssh";
            in
            [
              {
                path = "${dir}/ssh_host_ed25519_key";
                type = "ed25519";
              }
            ];
        };

        # ET server - enable but no firewall setting, so not exposed on proxy servers
        services.eternal-terminal.enable = true;

        # Read directly by openssh (not bind-mounted); declare for audit.
        my.persistence.externalPaths = [
          "/etc/ssh/ssh_host_ed25519_key"
          "/etc/ssh/ssh_host_ed25519_key.pub"
        ];
      };
    };

  flake.darwinModules.core = {
    services.openssh = {
      enable = true;
      extraConfig = ''
        PasswordAuthentication no
        PermitRootLogin no
      '';
    };

    services.eternal-terminal.enable = true;
  };

  flake.homeModules.core =
    { lib, pkgs, ... }:
    let
      ssh-agent-switcher = pkgs.ssh-agent-switcher.overrideAttrs { doCheck = false; };
    in
    {
      # SSH agent switcher daemon for stable agent forwarding in tmux/zellij
      programs.zsh.initContent = ''
        if [ -n "$SSH_CONNECTION" ]; then
          export SSH_AUTH_SOCK="/tmp/ssh-agent-switcher.''${USER}.sock"
          ${lib.getExe ssh-agent-switcher} --daemon --socket-path="$SSH_AUTH_SOCK" 2>/dev/null || true
        fi
      '';

      home.packages = [ pkgs.connect ];

      # Route ssh via the local proxy when $HTTP_PROXY is set.
      programs.ssh.settings.${''Match host * exec "test x''${HTTP_PROXY:+set} = xset"''}.proxyCommand =
        "${pkgs.connect}/bin/connect -h %h %p";
    };
}
