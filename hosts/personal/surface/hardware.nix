# Surface Pro 11 for Business (Intel, Lunar Lake)
{ inputs, ... }:
{

  flake.nixosModules.surface =
    { lib, pkgs, ... }:
    {
      # Firmware declares the one RT1320 twice; the ghost stops sof_sdw registering.
      boot.kernelPatches = [
        {
          name = "soundwire-dmi-quirks-surface-pro-11";
          patch = pkgs.fetchpatch {
            url = "https://patchwork.kernel.org/project/alsa-devel/patch/20260913210849.6446-1-lsa.uz@pm.me/mbox/";
            hash = "sha256-Zz8xRiQeI2U7TLIPGRVYgLUiliBXdk54fr4WatFyCZE=";
          };
        }
      ];

      specialisation.linux-surface.configuration = {
        imports = [ inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel ];
        boot.kernelPatches = lib.mkForce [ ];
      };
    };

}
