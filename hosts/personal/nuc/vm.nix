# Windows 11 VM with VFIO GPU passthrough (NixVirt declarative domain)
{ pkgs, inputs, ... }:
let
  passthrough = bus: slot: function: {
    mode = "subsystem";
    type = "pci";
    managed = true;
    source.address = {
      type = "pci";
      domain = 0;
      inherit bus slot function;
    };
  };

  hexInt = s: (fromTOML "v = 0x${s}").v;
  usb = vendor: product: {
    mode = "subsystem";
    type = "usb";
    managed = true;
    source = {
      vendor.id = hexInt vendor;
      product.id = hexInt product;
    };
  };

  win11 = {
    type = "kvm";
    name = "win11";
    uuid = "ae72c684-1013-11f1-8714-6b59c2146990";

    vcpu.count = 16;
    cpu = {
      mode = "host-passthrough";
      maxphysaddr = {
        mode = "passthrough";
        limit = 39;
      };
      topology = {
        sockets = 1;
        dies = 1;
        cores = 8;
        threads = 2;
      };
    };
    # 1:1 vCPU-to-pCPU pinning for P-cores (CPUs 0-15, 8 cores × 2 threads)
    cputune.vcpupin = builtins.genList (i: {
      vcpu = i;
      cpuset = toString i;
    }) 16;

    memory = {
      count = 32;
      unit = "GiB";
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
          name = "tsc";
          mode = "native";
        }
        {
          name = "hypervclock";
          present = true;
        }
        {
          name = "hpet";
          present = false;
        }
        {
          name = "pit";
          tickpolicy = "discard";
        }
        {
          name = "rtc";
          tickpolicy = "catchup";
        }
      ];
    };

    pm = {
      suspend-to-mem.enabled = false;
      suspend-to-disk.enabled = false;
    };

    devices = {
      hostdev = [
        (passthrough 1 0 0) # RTX 4080 GPU         (01:00.0)
        (passthrough 1 0 1) # RTX 4080 audio       (01:00.1)
        (passthrough 4 0 0) # Aquantia 10GbE       (04:00.0)
        (passthrough 2 0 0) # NVMe C:              (02:00.0)
        (passthrough 3 0 0) # NVMe D:              (03:00.0)
        (passthrough 8 0 0) # TB4 NHI              (08:00.0)
        (passthrough (hexInt "3c") 0 0) # TB4 USB  (3c:00.0)
        (usb "046d" "c548") # Logi Bolt Receiver
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
  imports = [ inputs.NixVirt.nixosModules.default ];

  virtualisation.libvirt.enable = true;
  virtualisation.libvirt.swtpm.enable = true;
  virtualisation.libvirtd.onShutdown = "shutdown";
  # Allow Windows Update to finish during host shutdown
  systemd.services.libvirt-guests.serviceConfig.TimeoutStopSec = "30min";

  virtualisation.libvirt.connections."qemu:///system".domains = [
    {
      definition = inputs.NixVirt.lib.domain.writeXML win11;
      active = null; # follow last state
      restart = false; # never kill VM during os switch
    }
  ];

  # Workaround: QEMU 10.2 has a bug where the TPM CRB chardev doesn't wake the
  # main event loop after sending a command to swtpm, causing OVMF to hang during
  # TPM init. Any QMP monitor command unblocks it by waking the main loop.
  systemd.services.win11-qemu-prod = {
    description = "Prod QEMU monitor on VM start (swtpm main loop wakeup bug)";
    after = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 2;
    };
    path = [ pkgs.libvirt ];
    script = ''
      prod() {
        echo "Prodding QEMU monitor (swtpm wakeup workaround)"
        for delay in 1 3 5 10; do
          sleep "$delay"
          virsh qemu-monitor-command win11 --hmp "info version" >/dev/null 2>&1 || return
        done
      }
      # Delayed prod catches VM autostart before the listener connects
      (sleep 2 && prod) &
      # Watch for all future start events
      virsh event --domain win11 --event lifecycle --loop | while read -r line; do
        if echo "$line" | grep -q "Started"; then
          prod
        fi
      done
    '';
  };

  environment.systemPackages = [ pkgs.virt-manager ];
}
