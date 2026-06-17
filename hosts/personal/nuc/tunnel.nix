# Reverse-SSH tunnel endpoint VM w/ QEMU user-mode networking.
{ inputs, ... }:
{
  flake.nixosModules.nuc-tunnel =
    { config, ... }:
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
    in
    {
      imports = [ inputs.microvm.nixosModules.host ];

      my.persistence.directories = [ config.microvm.stateDir ];

      microvm.vms.tunnel.config =
        { modulesPath, pkgs, ... }:
        {
          # nixpkgs' minimal profile (modulesPath = nixpkgs/nixos/modules).
          imports = [ "${modulesPath}/profiles/minimal.nix" ];
          system.stateVersion = "26.05";

          microvm = {
            interfaces = [
              {
                type = "user";
                id = "eth0";
                mac = "02:00:00:00:42:02";
              }
            ];
            forwardPorts = map (f: {
              host.port = f.host;
              guest.port = f.guest;
            }) ports;
            volumes = [
              {
                image = "persist.img";
                mountPoint = "/persist";
                size = 32;
              }
            ];
          };

          # QEMU SLIRP guest address; no gateway needed (no egress).
          networking.useDHCP = false;
          networking.usePredictableInterfaceNames = false;
          networking.interfaces.eth0.ipv4.addresses = [
            {
              address = "10.0.2.15";
              prefixLength = 24;
            }
          ];

          networking.nftables.enable = true;
          networking.firewall.allowedTCPPorts = map (f: f.guest) ports;
          # Egress lockdown: the VM may never initiate a connection.
          networking.nftables.tables.egress-lockdown = {
            family = "inet";
            content = ''
              chain output {
                type filter hook output priority 0; policy drop;
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
