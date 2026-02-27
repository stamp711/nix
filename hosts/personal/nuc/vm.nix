# Windows 11 VM with VFIO GPU passthrough (NixVirt declarative domain)
{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.my.win11-vm;

  # VM memory size in GiB, backed by 1G hugepages
  vmMemoryGiB = 40;

  # Front panel USB ports on bus 1 (PCH xHCI controller)
  vmFrontPanelPorts = [
    9
    10
    11
  ];

  pci = bus: slot: function: {
    mode = "subsystem";
    type = "pci";
    managed = true;
    source.address = {
      type = "pci";
      domain = 0;
      inherit bus slot function;
    };
  };

  # Long-running: watches for VM events and runs a callback on matches
  # Usage: vm-event-watcher <vm-name> <callback> <pattern>
  # Pattern is an extended regex matched for `grep -qiE` against virsh event output.
  vmEventWatcher = pkgs.writeShellScript "vm-event-watcher" ''
    VM="$1"
    CALLBACK="$2"
    PATTERN="$3"
    VIRSH="${pkgs.libvirt}/bin/virsh"

    # Catch VM already running (delayed to let event listener connect first)
    (sleep 5 && "$VIRSH" domstate "$VM" 2>/dev/null | grep -qE 'running|paused' && "$CALLBACK" "$VM") &

    # Watch for all future events, filter by pattern
    "$VIRSH" event --domain "$VM" --all --loop | while read -r line; do
      echo "$line"
      if echo "$line" | grep -qiE "$PATTERN"; then
        "$CALLBACK" "$VM"
      fi
    done
  '';

  # Callback: prod QEMU monitor to work around swtpm wakeup bug
  qemuProd = pkgs.writeShellScript "qemu-prod" ''
    VM="$1"
    VIRSH="${pkgs.libvirt}/bin/virsh"
    echo "Prodding QEMU monitor for $VM"
    for delay in 1 3 5 10; do
      sleep "$delay"
      "$VIRSH" qemu-monitor-command "$VM" --hmp "info version" >/dev/null 2>&1 || return
    done
  '';

  # Callback: scan front-panel USB ports and attach connected devices
  usbPassthroughScan = pkgs.writeShellScript "usb-passthrough-scan" ''
    VM="$1"
    echo "Scanning front-panel USB ports for $VM"
    for PORT in ${builtins.concatStringsSep " " (map toString vmFrontPanelPorts)}; do
      SYSPATH="/sys/bus/usb/devices/1-$PORT"
      [ -f "$SYSPATH/busnum" ] && ${virshUsbPassthrough} attach "$VM" "$SYSPATH"
    done
  '';

  # Attach/detach a single USB device (by sysfs path) to a VM via virsh
  virshUsbPassthrough = pkgs.writeShellScript "virsh-usb-passthrough" ''
    ACTION="$1"   # attach or detach
    VM="$2"       # VM name
    SYSPATH="$3"  # e.g. /sys/bus/usb/devices/1-9

    VIRSH="${pkgs.libvirt}/bin/virsh"

    # Bail if VM doesn't have an active QEMU process
    if ! "$VIRSH" domstate "$VM" 2>/dev/null | grep -qE 'running|paused'; then
      echo "$VM not active, skipping $ACTION for $SYSPATH"
      exit 0
    fi

    BUSNUM=$(cat "$SYSPATH/busnum")
    DEVNUM=$(cat "$SYSPATH/devnum")
    echo "$ACTION bus=$BUSNUM dev=$DEVNUM ($SYSPATH) -> $VM"

    XML="<hostdev mode='subsystem' type='usb' managed='yes'>
      <source><address bus='$BUSNUM' device='$DEVNUM'/></source>
    </hostdev>"

    echo "$XML" | "$VIRSH" "$ACTION-device" "$VM" /dev/stdin
  '';

  win11 = {
    type = "kvm";
    name = "win11";
    uuid = "ae72c684-1013-11f1-8714-6b59c2146990";

    vcpu.count = 16;
    cpu = {
      mode = "host-passthrough";
      features = [
        {
          name = "vmx";
          policy = "disable";
        }
      ];
      topology = {
        sockets = 1;
        dies = 1;
        # 8Cx2T to match P-cores
        cores = 8;
        threads = 2;
      };
    };
    # 1:1 pinning for P-cores (CPUs 0-15, 8Cx2T)
    cputune.vcpupin = builtins.genList (i: {
      vcpu = i;
      cpuset = toString i;
    }) 16;

    memory = {
      count = vmMemoryGiB;
      unit = "GiB";
    };
    memoryBacking = {
      hugepages = {
        page = {
          size = 1;
          unit = "GiB";
        };
      };
      nosharepages = { };
      locked = { };
    };

    os = {
      type = "hvm";
      arch = "x86_64";
      machine = "q35";
      loader = {
        readonly = true;
        type = "pflash";
        path = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd";
      };
      nvram = {
        template = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd";
        path = "/var/lib/libvirt/qemu/nvram/win11_VARS.fd";
      };
    };

    features = {
      acpi = { };
      apic = { };
      hyperv.mode = "passthrough";
    };

    clock = {
      offset = "localtime";
      timer = [
        {
          name = "hypervclock";
          present = true;
        }
        {
          name = "hpet";
          present = false;
        }
      ];
    };

    pm = {
      suspend-to-mem.enabled = false;
      suspend-to-disk.enabled = false;
    };

    devices = {
      memballoon.model = "none";
      hostdev = [
        (pci 1 0 0) # RTX 4080 GPU         (01:00.0)
        (pci 1 0 1) # RTX 4080 audio       (01:00.1)
        (pci 4 0 0) # Aquantia 10GbE       (04:00.0)
        (pci 2 0 0) # NVMe C:              (02:00.0)
        (pci 3 0 0) # NVMe D:              (03:00.0)
        (pci 8 0 0) # TB4 NHI              (08:00.0)
        (pci (lib.fromHexString "3c") 0 0) # TB4 USB  (3c:00.0)
      ];
      channel = [
        {
          type = "unix";
          target = {
            type = "virtio";
            name = "org.qemu.guest_agent.0";
          };
        }
      ];
      tpm = {
        model = "tpm-crb";
        backend = {
          type = "emulator";
          version = "2.0";
        };
      };
    };

    qemu-commandline.arg = [
      # Tell OVMF to allocate 64GB of 64-bit MMIO space for large BARs (ReBAR)
      { value = "-fw_cfg"; }
      { value = "opt/ovmf/X-PciMmio64Mb,string=65536"; }
      # Match host SMBIOS so Windows activation persists between VM and bare metal
      { value = "-smbios"; }
      { value = "type=1,manufacturer=Intel(R) Client Systems,product=NUC13RNGi9,family=RN"; }
      { value = "-smbios"; }
      { value = "type=2,manufacturer=Intel Corporation,product=NUC13SBBi9"; }
    ];
  };
in
{
  options.my.win11-vm.enable = lib.mkEnableOption "Windows 11 VM with VFIO GPU passthrough" // {
    default = true;
  };

  imports = [ inputs.NixVirt.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    # VFIO: bind GPU, GPU audio, and 10GbE NIC to vfio-pci at boot
    boot.initrd.kernelModules = [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
    ];
    boot.kernelParams = [
      "hugepagesz=1G"
      "hugepages=${toString vmMemoryGiB}"
      # 10de:2704 = RTX 4080 GPU
      # 10de:22bb = RTX 4080 audio
      # 1d6a:14c0 = Aquantia 10GbE
      "vfio-pci.ids=10de:2704,10de:22bb,1d6a:14c0"
    ];

    # Mount hugetlbfs for 1 GiB hugepages
    fileSystems."/dev/hugepages1G" = {
      device = "hugetlbfs";
      fsType = "hugetlbfs";
      options = [ "pagesize=1G" ];
    };

    virtualisation.libvirt.enable = true;
    virtualisation.libvirt.swtpm.enable = true;
    virtualisation.libvirtd.onShutdown = "shutdown";

    virtualisation.libvirt.connections."qemu:///system".domains = [
      {
        definition = inputs.NixVirt.lib.domain.writeXML win11;
        active = true; # start the domain at activation time
        restart = false; # do not restart even if definition changed
      }
    ];

    # Workaround: QEMU 10.2 has a bug where the TPM CRB chardev doesn't wake the
    # main event loop after sending a command to swtpm, causing OVMF to hang during
    # TPM init. Any QMP monitor command unblocks it by waking the main loop.
    systemd.services.win11-qemu-prod-watcher = {
      description = "Prod QEMU monitor on VM start (workaround for swtpm main loop wakeup bug)";
      after = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Restart = "always";
        RestartSec = 2;
        ExecStart = "${vmEventWatcher} win11 ${qemuProd} 'started|reboot|crashed'";
      };
    };

    # Auto-passthrough front panel USB ports to win11 VM on start
    systemd.services.win11-usb-passthrough-watcher = {
      description = "Watch for win11 VM starts and attach front-panel USB devices";
      after = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Restart = "always";
        RestartSec = 2;
        ExecStart = "${vmEventWatcher} win11 ${usbPassthroughScan} started";
      };
    };

    # Graceful shutdown via guest agent (libvirt-guests.service)
    systemd.services.win11-shutdown = {
      description = "Gracefully shut down win11 VM via guest agent";
      after = [
        "libvirtd.service"
        "libvirt-guests.service"
      ];
      wantedBy = [ "multi-user.target" ];
      stopIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${pkgs.libvirt}/bin/virsh shutdown win11 --mode agent";
        TimeoutStopSec = "30min";
      };
    };

    # Hot-plug: attach USB devices on front panel ports when plugged in while VM is running
    services.udev.extraRules = builtins.concatStringsSep "\n" (
      map (port: ''
        ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{busnum}=="1", ATTR{devpath}=="${toString port}", RUN+="${virshUsbPassthrough} attach win11 /sys$env{DEVPATH}"
      '') vmFrontPanelPorts
    );

    environment.systemPackages = [ pkgs.virt-manager ];
    environment.variables.LIBVIRT_DEFAULT_URI = "qemu:///system";
  };
}
