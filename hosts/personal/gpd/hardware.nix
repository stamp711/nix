# GPD Pocket 4 hardware (AMD Ryzen AI HX 370)
{
  # Force 10bpc to work around Apple Studio Display tile mismatch on Strix Point.
  # One tile reports 12bpc+DSC, the other 10bpc only - forcing 10bpc makes them match.
  # ref: https://gitlab.freedesktop.org/drm/amd/-/issues/4734
  # boot.kernelPatches = [
  #   {
  #     name = "amdgpu-force-10bpc";
  #     patch = ./amdgpu-force-10bpc.patch;
  #   }
  # ];
}
