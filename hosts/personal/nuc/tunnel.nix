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
      userName = "tunnel";

      # SSH keys allowed to open the tunnel.
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

      # passt gives the VM user-mode networking over a unix socket.
      systemd.services.passt-tunnel = {
        description = "passt networking for the tunnel microVM";
        before = [ "microvm@tunnel.service" ];
        requiredBy = [ "microvm@tunnel.service" ];
        # After nftables so the egress-guard set exists when systemd registers
        # this unit's cgroup into the NFTSet below.
        after = [ "nftables.service" ];
        serviceConfig = {
          User = "microvm";
          RuntimeDirectory = "passt-tunnel";
          # Register this unit's cgroup into the egress-guard set.
          NFTSet = "cgroup:inet:tunnel_egress:passt";
          ExecStart = lib.concatStringsSep " " [
            "${pkgs.passt}/bin/passt"
            "--foreground"
            "--quiet"
            "--socket ${passtSocket}"
            "--address ${guestAddress}"
            "--netmask ${toString guestPrefix}"
            "--gateway ${guestGateway}"
            "--tcp-ports ${passtPorts}"
            # Forward only the ports above; don't route to the host.
            "--no-map-gw"
            "--no-dhcp-dns"
            "--no-udp"
            "--no-icmp" # implies --no-ndp
            "--no-dhcpv6"
            "--no-ra"
          ];
          Restart = "on-failure";
        };
      };

      # Host-side egress guard
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
          # passt does inbound-only forwarding: allow its replies, drop the rest.
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
            # Networking is wired to passt over the unix socket.
            qemu.extraArgs = [
              "-netdev"
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
              UsePAM = false;
              PermitRootLogin = "no";
              AllowUsers = [ userName ];
              AllowTcpForwarding = "remote";
              GatewayPorts = "clientspecified";
              ClientAliveInterval = 30;
              ClientAliveCountMax = 3;
              # Forwarding only, no shell/exec/subsystem sessions.
              MaxSessions = 0;
              # Flood resistance:
              LoginGraceTime = 20; # the window to finish authenticating
              MaxStartups = "3:50:10"; # caps concurrent unauthenticated connections, start:drop_rate:full
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

          security.protectKernelImage = true; # no kexec
          boot.kernel.sysctl."kernel.kptr_restrict" = 2;
          boot.kernel.sysctl."kernel.dmesg_restrict" = 1;
        };
    };
}
