# GPD Pocket 4 hardware (AMD Ryzen AI HX 370)
{ inputs, ... }: {

  flake.nixosModules.gpd = {
    imports = [ inputs.nixos-hardware.nixosModules.gpd-pocket-4 ];

    # Force 10bpc to work around Apple Studio Display tile mismatch on Strix Point.
    # One tile reports 12bpc+DSC, the other 10bpc only - forcing 10bpc makes them match.
    # ref: https://gitlab.freedesktop.org/drm/amd/-/issues/4734
    boot.kernelPatches = [
      {
        name = "amdgpu-force-10bpc";
        patch = ./amdgpu-force-10bpc.patch;
      }
    ];
  };

  flake.homeModules.gpd = {
    # Panel is mounted portrait; rotate 270° CW to display landscape.
    wayland.windowManager.hyprland.settings.monitor = [
      {
        output = "eDP-1";
        transform = 3;
      }
    ];
  };

}
