{ lib, ... }:
{
  flake.nixosModules.my =
    {
      config,
      pkgs,
      utils,
      ...
    }:
    let
      cfg = config.my.boot-disk;
      diskDevice = lib.mkOption {
        type = lib.types.str;
        description = "Disk to partition. Prefer a stable /dev/disk/by-id path.";
      };
      luksEnable = lib.mkOption {
        type = lib.types.bool;
        description = "Encrypt the root partition with LUKS.";
      };
      btrfsSwapSize = lib.mkOption {
        type = lib.types.str;
        default = "16G";
        description = "Size of the btrfs swapfile.";
      };
      btrfsWipeTargets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "@root" ];
        example = [
          "@root"
          "@home"
        ];
        description = ''
          btrfs subvolumes to wipe on each boot by rolling back to @blank
          in initrd. Empty list disables the rollback (staging mode);
          my.persistence bind mounts still apply.

          Pre-populate /persist/... (via my.persistence.* declarations)
          with anything in a wipe target that you need to survive — wiped
          state with no persistence is lost.
        '';
      };
    in
    {
      options.my.boot-disk = {
        enable = lib.mkEnableOption "declarative disk layout via disko";
        layout = lib.mkOption {
          description = "Disk layout to apply. Exactly one variant, carrying only its own settings.";
          type = lib.types.attrTag {
            efi-btrfs = lib.mkOption {
              description = "Whole disk: ESP plus a Btrfs root, optionally LUKS-encrypted.";
              type = lib.types.submodule {
                options = {
                  device = diskDevice;
                  luks = luksEnable;
                  swapSize = btrfsSwapSize;
                  wipeTargets = btrfsWipeTargets;
                };
              };
            };
            mbr-ext4 = lib.mkOption {
              description = "Whole disk: BIOS boot partition plus an ext4 root.";
              type = lib.types.submodule { options.device = diskDevice; };
            };
            efi-btrfs-partitions = lib.mkOption {
              description = ''
                Like efi-btrfs, but on partitions that already exist. Nothing
                here writes a partition table, so the disk may belong to
                another OS; create the partitions before installing.
              '';
              type = lib.types.submodule {
                options = {
                  esp = lib.mkOption {
                    type = lib.types.str;
                    description = "Our own ESP (type EF00), formatted and mounted at /boot.";
                  };
                  root = lib.mkOption {
                    type = lib.types.str;
                    description = "Partition holding the Btrfs root.";
                  };
                  luks = luksEnable;
                  swapSize = btrfsSwapSize;
                  wipeTargets = btrfsWipeTargets;
                };
              };
            };
          };
        };
      };

      config = lib.mkIf cfg.enable (
        let
          luksName = "cryptroot";

          btrfsContent = v: {
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
              "@swap".swap.swapfile.size = v.swapSize;

              "@blank" = { };
              "@persist".mountpoint = config.my.persistence.path;
            };
          };

          rootContent =
            v:
            if v.luks then
              {
                type = "luks";
                name = luksName;
                settings.allowDiscards = true;
                content = btrfsContent v;
              }
            else
              btrfsContent v;

          # What a Btrfs root needs beyond its own partitions.
          btrfsRoot =
            v:
            let
              rootDevice = config.fileSystems."/".device;
              rollbackDependency =
                if v.luks then
                  "systemd-cryptsetup@${luksName}.service"
                else
                  "${utils.escapeSystemdPath rootDevice}.device";

              rollbackScript = pkgs.writeShellScriptBin "rollback-subvols" /* bash */ ''
                set -eu

                if [ "$#" -eq 0 ]; then
                  echo "usage: rollback-subvols <subvolume>..."
                  exit 1
                fi

                mkdir -p /btrfs_tmp
                ${pkgs.util-linux.mount}/bin/mount -t btrfs -o subvol=/ ${lib.escapeShellArg rootDevice} /btrfs_tmp
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
            lib.mkMerge [
              {
                my.persistence.enable = true;
                # impermanence asserts on this; agenix also reads from /persist
                # at activation time, so the mount must be in initrd.
                fileSystems.${config.my.persistence.path}.neededForBoot = true;
                boot.loader.systemd-boot.enable = true;
                boot.loader.efi.canTouchEfiVariables = true;
                boot.initrd.systemd.enable = true;
              }

              # Listing any subvol in wipeTargets gives impermanence for it.
              (lib.mkIf (v.wipeTargets != [ ]) {
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
                  description = "Wipe btrfs subvolumes: ${lib.concatStringsSep " " v.wipeTargets}";
                  requiredBy = [ "initrd.target" ];
                  requires = [ rollbackDependency ];
                  after = [ rollbackDependency ];
                  before = [ "sysroot.mount" ];
                  unitConfig.DefaultDependencies = false;
                  serviceConfig = {
                    Type = "oneshot";
                    ExecStart = "${lib.getExe rollbackScript} ${lib.concatStringsSep " " v.wipeTargets}";
                  };
                };
              })
            ];
        in
        lib.mkMerge [

          (lib.mkIf (cfg.layout ? efi-btrfs) (
            let
              v = cfg.layout.efi-btrfs;
            in
            lib.mkMerge [
              (btrfsRoot v)
              {
                disko.devices.disk.main = {
                  inherit (v) device;
                  type = "disk";
                  content = {
                    type = "gpt";
                    partitions.ESP = {
                      size = "1G";
                      type = "EF00";
                      content = {
                        type = "filesystem";
                        format = "vfat";
                        mountpoint = "/boot";
                        mountOptions = [ "umask=0077" ];
                      };
                    };
                    partitions.root = {
                      size = "100%";
                      content = rootContent v;
                    };
                  };
                };
              }
            ]
          ))

          (lib.mkIf (cfg.layout ? efi-btrfs-partitions) (
            let
              v = cfg.layout.efi-btrfs-partitions;
            in
            lib.mkMerge [
              (btrfsRoot v)
              {
                disko.devices.disk = {
                  esp = {
                    device = v.esp;
                    type = "disk";
                    content = {
                      type = "filesystem";
                      format = "vfat";
                      mountpoint = "/boot";
                      mountOptions = [ "umask=0077" ];
                    };
                  };
                  root = {
                    device = v.root;
                    type = "disk";
                    content = rootContent v;
                  };
                };
              }
            ]
          ))

          (lib.mkIf (cfg.layout ? mbr-ext4) {
            boot.loader.grub.enable = true;
            disko.devices.disk.main = {
              device = cfg.layout.mbr-ext4.device;
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
