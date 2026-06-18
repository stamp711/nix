# charon: domain-allowlisted forward proxy (tinyproxy) behind SSH, egress via Surge.
{ inputs, ... }:
{
  flake.nixosModules.charon =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      userName = "psyche";

      proxyKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDuNXgUoOwCVdvkegE+FGP77qdyWEQFqcRgIY0d6lKeh" # 1Password
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGGfAr2tMhcrbtdxi2RjGCaXCTQGWB3dBlTEXN6/DUxE" # dev
      ];

      sshPort = 58023; # external (passt) -> guest sshd
      proxyPort = 6150; # loopback proxy, reached via ssh -L

      # Egress upstream: Surge's HTTP proxy, which relays out to snell on "via".
      upstream = {
        scheme = "http";
        host = "10.0.10.10";
        port = 6150;
      };

      passtRuntimeDir = "passt/charon"; # relative: systemd RuntimeDirectory= rejects absolute
      passtSocket = "/run/${passtRuntimeDir}/passt.sock";

      # The only domains the proxy will reach (matched as domain + subdomains).
      allowedDomains = [
        "google.com"
        "github.com"
        "deepwiki.com"
        "linear.app"

        "anthropic.com"
        "claude.ai"
        "claude.com"
        "cdn.usefathom.com"
        "datadoghq.com"
      ];

      filterFile = pkgs.writeText "charon-allow" (
        lib.concatMapStringsSep "\n" (
          d: "(^|\\.)" + lib.replaceStrings [ "." ] [ "\\." ] d + "$"
        ) allowedDomains
        + "\n"
      );
    in
    {
      imports = [ inputs.microvm.nixosModules.host ];

      my.persistence.directories = [ "${config.microvm.stateDir}/charon" ];

      systemd.services.passt-charon = {
        description = "passt networking for the charon microVM";
        before = [ "microvm@charon.service" ];
        requiredBy = [ "microvm@charon.service" ];
        after = [ "nftables.service" ]; # egress-guard set must exist before NFTSet
        serviceConfig = {
          User = "microvm";
          RuntimeDirectory = passtRuntimeDir;
          NFTSet = "cgroup:inet:charon_egress:charon";
          ExecStart = lib.concatStringsSep " " [
            "${pkgs.passt}/bin/passt"
            "--foreground"
            "--quiet"
            "--socket ${passtSocket}"
            "--address 10.0.2.15"
            "--netmask 24"
            "--gateway 10.0.2.2"
            "--tcp-ports ${toString sshPort}:22"
            "--no-map-gw" # no route to the host
            "--no-dhcp-dns"
            "--no-udp"
            "--no-icmp" # implies --no-ndp
            "--no-dhcpv6"
            "--no-ra"
          ];
          Restart = "on-failure";
        };
      };

      # Host backstop: only allow VM replies + reach upstream proxy.
      networking.nftables.enable = true;
      networking.nftables.checkRuleset = false; # build-time check sandbox kernel lacks `socket cgroupv2` support.
      networking.nftables.tables.charon_egress = {
        family = "inet";
        content = ''
          set charon {
            type cgroupsv2
          }
          chain output {
            type filter hook output priority filter; policy accept;
            socket cgroupv2 level 2 @charon jump charon-egress
          }
          chain charon-egress {
            ct state established,related accept
            ip daddr ${upstream.host} tcp dport ${toString upstream.port} accept
            counter drop
          }
        '';
      };

      microvm.vms.charon.config =
        { modulesPath, pkgs, ... }:
        {
          # nixpkgs' minimal profile (modulesPath = nixpkgs/nixos/modules).
          imports = [ "${modulesPath}/profiles/minimal.nix" ];
          system.stateVersion = "26.05";

          microvm = {
            qemu.extraArgs = [
              "-netdev"
              # reconnect-ms: tolerate passt (re)starts and startup ordering
              "stream,id=net0,addr.type=unix,addr.path=${passtSocket},reconnect-ms=1000"
              "-device"
              "virtio-net-device,netdev=net0"
            ];
            volumes = [
              {
                image = "persist.img";
                mountPoint = "/persist";
                size = 32;
              }
            ];
          };

          # Egress locked to the upstream (tinyproxy never resolves origins).
          networking.nftables.enable = true;
          networking.nftables.tables.egress = {
            family = "inet";
            content = ''
              chain output {
                type filter hook output priority filter; policy drop;
                ct state established,related accept
                oifname "lo" accept
                ip daddr ${upstream.host} tcp dport ${toString upstream.port} accept
              }
            '';
          };

          # SSH front: key-gated, can only -L to the proxy port (no shell, no egress).
          services.openssh = {
            enable = true;
            hostKeys = [
              {
                path = "/persist/ssh_host_ed25519_key";
                type = "ed25519";
              }
            ];
            settings = {
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
              PermitRootLogin = "no";
              AllowUsers = [ userName ];
              AllowTcpForwarding = "local";
              ClientAliveInterval = 30;
              ClientAliveCountMax = 3;
              MaxSessions = 0; # forwarding only, no shell/exec
              LoginGraceTime = 20;
              MaxStartups = "3:50:10";
            };
          };
          users.users.${userName} = {
            isSystemUser = true;
            group = userName;
            shell = "${pkgs.shadow}/bin/nologin";
            openssh.authorizedKeys.keys = map (
              k: ''restrict,permitopen="127.0.0.1:${toString proxyPort}",port-forwarding ${k}''
            ) proxyKeys;
          };
          users.groups.${userName} = { };

          # Deny-by-default domain allowlist; forward everything to the upstream.
          # A non-matching host (incl. raw IP literals) is refused -> no SSRF/LAN.
          services.tinyproxy = {
            enable = true;
            settings = {
              Listen = "127.0.0.1";
              Port = proxyPort;
              Allow = "127.0.0.1";
              FilterDefaultDeny = "Yes";
              FilterExtended = "Yes";
              Filter = "${filterFile}";
              Upstream = "${upstream.scheme} ${upstream.host}:${toString upstream.port}";
              DisableViaHeader = "Yes";
            };
          };

          services.timesyncd.enable = false;
          console.enable = false;
          powerManagement.enable = false;
          nix.enable = false;

          # guest logs surface in host journalctl -u microvm@charon
          services.journald.extraConfig = "ForwardToConsole=yes";

          security.protectKernelImage = true; # no kexec
          boot.kernel.sysctl."kernel.kptr_restrict" = 2;
          boot.kernel.sysctl."kernel.dmesg_restrict" = 1;
        };
    };
}
