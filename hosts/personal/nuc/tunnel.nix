# Reverse-SSH tunnel endpoint VM w/ passt networking.
{ inputs, ... }:
{
  flake.nixosModules.nuc-tunnel =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      userName = "theseus";

      tunnelKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDuNXgUoOwCVdvkegE+FGP77qdyWEQFqcRgIY0d6lKeh" # 1Password
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGGfAr2tMhcrbtdxi2RjGCaXCTQGWB3dBlTEXN6/DUxE" # dev
      ];

      ports = [
        {
          host = 58022;
          guest = 22;
        }
        {
          host = 58082;
          guest = 58082;
        }
      ];

      # passt private guest network; egress is firewalled off below.
      guestGateway = "10.0.2.2";
      guestAddress = "10.0.2.15";
      guestPrefix = 24;

      # host:guest spec for passt --tcp-ports
      passtPorts = lib.concatMapStringsSep "," (f: "${toString f.host}:${toString f.guest}") ports;
      passtSocket = "/run/passt-tunnel/passt.sock";
    in
    {
      imports = [ inputs.microvm.nixosModules.host ];

      my.persistence.directories = [ config.microvm.stateDir ];

      systemd.services.passt-tunnel = {
        description = "passt networking for the tunnel microVM";
        before = [ "microvm@tunnel.service" ];
        requiredBy = [ "microvm@tunnel.service" ];
        after = [ "nftables.service" ]; # egress-guard set must exist before NFTSet
        serviceConfig = {
          User = "microvm";
          RuntimeDirectory = "passt-tunnel";
          NFTSet = "cgroup:inet:tunnel_egress:passt"; # adds passt's cgroup to the egress-guard set
          ExecStart = lib.concatStringsSep " " [
            "${pkgs.passt}/bin/passt"
            "--foreground"
            "--quiet"
            "--socket ${passtSocket}"
            "--address ${guestAddress}"
            "--netmask ${toString guestPrefix}"
            "--gateway ${guestGateway}"
            "--tcp-ports ${passtPorts}"
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

      networking.nftables.enable = true;
      # The build-time check sandbox kernel lacks `socket cgroupv2` support.
      networking.nftables.checkRuleset = false;
      networking.nftables.tables.tunnel_egress = {
        family = "inet";
        content = ''
          set passt {
            type cgroupsv2
          }
          chain output {
            type filter hook output priority filter; policy accept;
            socket cgroupv2 level 2 @passt jump passt-egress
          }
          # inbound-only: allow replies, drop anything passt initiates
          chain passt-egress {
            ct state established,related accept
            counter drop
          }
        '';
      };

      microvm.vms.tunnel.config =
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

          networking.nftables.enable = true;
          networking.firewall.allowedTCPPorts = map (f: f.guest) ports;
          # Egress lockdown: the VM may never initiate a connection.
          networking.nftables.tables.egress-lockdown = {
            family = "inet";
            content = ''
              chain output {
                type filter hook output priority filter; policy drop;
                ct state established,related accept
                oifname "lo" accept
              }
            '';
          };

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
              AllowTcpForwarding = "remote";
              GatewayPorts = "clientspecified";
              ClientAliveInterval = 30;
              ClientAliveCountMax = 3;
              MaxSessions = 0; # forwarding only, no shell/exec sessions
              LoginGraceTime = 20;
              MaxStartups = "3:50:10"; # concurrent unauthed conns: start:drop%:full
            };
          };

          users.users.${userName} = {
            isSystemUser = true;
            group = "${userName}";
            shell = "${pkgs.shadow}/bin/nologin";
            openssh.authorizedKeys.keys = map (k: "restrict,port-forwarding ${k}") tunnelKeys;
          };
          users.groups.${userName} = { };

          services.timesyncd.enable = false;
          console.enable = false;
          powerManagement.enable = false;
          nix.enable = false;

          # guest logs surface in host journalctl -u microvm@tunnel
          services.journald.extraConfig = "ForwardToConsole=yes";

          security.protectKernelImage = true; # no kexec
          boot.kernel.sysctl."kernel.kptr_restrict" = 2;
          boot.kernel.sysctl."kernel.dmesg_restrict" = 1;
        };
    };
}
