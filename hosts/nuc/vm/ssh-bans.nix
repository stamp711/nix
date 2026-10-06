# Scanner bans for sshd in the ariadne & charon guests.
{
  flake.nixosModules.nuc =
    let
      bans = {
        # Ban a source that opens SSH connections too fast.
        networking.nftables.tables.ssh-bans = {
          family = "inet";
          content = ''
            set ssh_meter {
              type ipv4_addr
              flags dynamic
              timeout 10m
            }
            set ssh_block {
              type ipv4_addr
              flags dynamic
              timeout 10m
            }
            chain input {
              type filter hook input priority filter; policy accept;
              tcp dport 22 ct state new ip saddr @ssh_block counter drop
              tcp dport 22 ct state new add @ssh_meter { ip saddr limit rate over 15/minute burst 5 packets } add @ssh_block { ip saddr } counter drop
            }
          '';
        };

        # Ban a source on its first wrong username.
        services.fail2ban = {
          enable = true;
          jails.sshd.settings.enabled = false;
          jails.ssh-wrong-user.settings = {
            enabled = true;
            filter = "ssh-wrong-user";
            port = "22";
            maxretry = 1;
            bantime = "10m";
            # Drop instead of the stock action reject.
            action = ''nftables[type=multiport, blocktype=drop, port="%(port)s"]'';
          };
        };

        # Greedy .* and the end anchors: a username crafted as "x from 1.2.3.4 ..."
        # cannot spoof <HOST>.
        environment.etc."fail2ban/filter.d/ssh-wrong-user.conf".text = ''
          [Definition]
          failregex = ^Invalid user .* from <HOST> port \d+$
                      ^User .* from <HOST> not allowed because not listed in AllowUsers$
          journalmatch = SYSLOG_IDENTIFIER=sshd-session
        '';
      };
    in
    {
      microvm.vms.ariadne.config = bans;
      microvm.vms.charon.config = bans;
    };
}
