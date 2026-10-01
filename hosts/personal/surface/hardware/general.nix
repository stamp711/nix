# Surface Pro 11 for Business (Intel, Lunar Lake)
{ inputs, ... }:
{
  flake.nixosModules.surface =
    { lib, pkgs, ... }:
    {

      boot.kernelPatches = [
        {
          # Firmware declares the one RT1320 twice; the ghost stops sof_sdw registering.
          # Kernel mailing list has a pending patch for this:
          name = "soundwire-dmi-quirks-surface-pro-11";
          patch = pkgs.fetchpatch {
            url = "https://patchwork.kernel.org/project/alsa-devel/patch/20260913210849.6446-1-lsa.uz@pm.me/mbox/";
            hash = "sha256-Zz8xRiQeI2U7TLIPGRVYgLUiliBXdk54fr4WatFyCZE=";
          };
        }
        {
          # Arm the lid's GPE for wake on the Intel Surface Pro 11 (SKU 2103).
          name = "surface-pro-11-intel-lid-wake";
          patch = pkgs.fetchpatch {
            url = "https://github.com/linux-surface/kernel/commit/1bfb647cd119dbea7189d199b6c543e2e7621acb.patch";
            hash = "sha256-JzRQwPA/a1tkfO8ChCaQ1WpVeUhGRtObudVuW0Wvjbk=";
          };
        }
        {
          # Fix hibernation thaw and missed Bluetooth power-state interrupts. Backport of
          # https://lore.kernel.org/lkml/20260928171003.2925480-1-ravindra@intel.com/
          name = "btintel-pcie-pm";
          patch = ./btintel-pcie-pm.patch;
        }
      ];

      specialisation.linux-surface.configuration = {
        imports = [ inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel ];
        boot.kernelPatches = lib.mkForce [ ];
      };

    };
}
