{
  flake.nixosModules.my =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.boot-disk;

      espPartition = {
        size = "1G";
        type = "EF00";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = [ "umask=0077" ];
        };
      };

      luksName = "cryptroot";

      btrfsContent = {
        type = "btrfs";
        mountOptions = [
          "noatime"
          "ssd"
          "compress=zstd:3"
          "space_cache=v2"
          "discard=async"
        ];
        extraArgs = [ "-f" ];
        subvolumes = {
          "@root".mountpoint = "/";
          "@nix".mountpoint = "/nix";
          "@home".mountpoint = "/home";
          "@swap".mountpoint = "/.swap";
          "@swap".swap.swapfile.size = cfg.swapSize;

          "@blank" = { };
          "@persist".mountpoint = config.my.persistence.path;
        };
      };

      rollbackScript = pkgs.writeShellScriptBin "rollback-subvols" ''
        set -eu

        if [ "$#" -eq 0 ]; then
          echo "usage: rollback-subvols <subvolume>..."
          exit 1
        fi

        mkdir -p /btrfs_tmp
        ${pkgs.util-linux.mount}/bin/mount -t btrfs -o subvol=/ /dev/mapper/${luksName} /btrfs_tmp
        trap '${pkgs.util-linux.mount}/bin/umount /btrfs_tmp 2>/dev/null || true' EXIT

        # Refuse to wipe if @blank is missing
        if ! [ -e /btrfs_tmp/@blank ]; then
          echo "rollback-subvols: @blank missing, aborting"
          exit 1
        fi

        # -R handles any nested subvolumes created at runtime (podman, snapper, etc.).
        for target in "$@"; do
          if [ -e "/btrfs_tmp/$target" ]; then
            ${pkgs.btrfs-progs}/bin/btrfs subvolume delete -R "/btrfs_tmp/$target"
          fi
          ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot /btrfs_tmp/@blank "/btrfs_tmp/$target"
        done
      '';
    in
    {
      options.my.boot-disk = {
        enable = lib.mkEnableOption "declarative disk layout via disko";
        layout = lib.mkOption {
          type = lib.types.enum [
            "efi-btrfs"
            "efi-luks-btrfs"
            "mbr-ext4"
          ];
        };
        device = lib.mkOption {
          type = lib.types.str;
        };
        swapSize = lib.mkOption {
          type = lib.types.str;
          default = "16G";
        };
        wipeTargets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [
            "@root"
            "@home"
          ];
          description = ''
            btrfs subvolumes to wipe on each boot by rolling back to @blank
            in initrd. Only effective on a luks+btrfs layout. Empty list
            disables the rollback (staging mode); my.persistence bind mounts
            still apply.

            Pre-populate /persist/... (via my.persistence.* declarations)
            with anything in a wipe target that you need to survive — wiped
            state with no persistence is lost.
          '';
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [

          # efi-btrfs layout
          # TODO: unused; revisit if a non-luks host appears, or drop.
          (lib.mkIf (cfg.layout == "efi-btrfs") {
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;
            disko.devices.disk.main = {
              inherit (cfg) device;
              type = "disk";
              content = {
                type = "gpt";
                partitions.ESP = espPartition;
                partitions.root = {
                  size = "100%";
                  content = btrfsContent;
                };
              };
            };
          })

          # efi-luks-btrfs layout: subvolumes always include @blank/@persist;
          # listing any subvol in wipeTargets gives impermanence for that subvol.
          (lib.mkIf (cfg.layout == "efi-luks-btrfs") (
            lib.mkMerge [
              {
                my.persistence.enable = true;
                # impermanence asserts on this; agenix also reads from /persist
                # at activation time, so the mount must be in initrd.
                fileSystems.${config.my.persistence.path}.neededForBoot = true;
                boot.loader.systemd-boot.enable = true;
                boot.loader.efi.canTouchEfiVariables = true;
                boot.initrd.systemd.enable = true;
                disko.devices.disk.main = {
                  inherit (cfg) device;
                  type = "disk";
                  content = {
                    type = "gpt";
                    partitions.ESP = espPartition;
                    partitions.root = {
                      size = "100%";
                      content = {
                        type = "luks";
                        name = luksName;
                        settings.allowDiscards = true;
                        content = btrfsContent;
                      };
                    };
                  };
                };
              }
              (lib.mkIf (cfg.wipeTargets != [ ]) {
                # Drop to an initrd shell if rollback fails
                boot.initrd.systemd.emergencyAccess = true;
                boot.initrd.systemd.initrdBin = [ rollbackScript ];
                # Script references util-linux.mount and btrfs-progs by
                # absolute store path; explicit storePaths because initrdBin
                # doesn't recursively trace runtime closures.
                boot.initrd.systemd.storePaths = [
                  pkgs.util-linux.mount
                  pkgs.btrfs-progs
                ];
                boot.initrd.systemd.services.rollback-subvols = {
                  description = "Wipe btrfs subvolumes: ${lib.concatStringsSep " " cfg.wipeTargets}";
                  requiredBy = [ "initrd.target" ];
                  requires = [ "systemd-cryptsetup@${luksName}.service" ];
                  after = [ "systemd-cryptsetup@${luksName}.service" ];
                  before = [ "sysroot.mount" ];
                  unitConfig.DefaultDependencies = false;
                  serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${lib.getExe rollbackScript} ${lib.concatStringsSep " " cfg.wipeTargets}";
                  };
                };
              })
            ]
          ))

          # mbr-ext4 layout
          (lib.mkIf (cfg.layout == "mbr-ext4") {
            boot.loader.grub.enable = true;
            disko.devices.disk.main = {
              inherit (cfg) device;
              type = "disk";
              content = {
                type = "gpt";
                partitions.boot = {
                  size = "1M";
                  type = "EF02";
                };
                partitions.root = {
                  size = "100%";
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/";
                  };
                };
              };
            };
          })

        ]
      );
    };
}
