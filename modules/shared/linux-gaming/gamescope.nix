{
  flake.nixosModules.linux-gaming =
    { pkgs, ... }:
    {
      programs.gamescope = {
        enable = true;
        # bwrap: setuid use of bubblewrap is not supported in this build
        # https://github.com/NixOS/nixpkgs/issues/523200
        capSysNice = false;
      };
      # WSI Vulkan layer for HDR + frame pacing under gamescope.
      environment.systemPackages = [ pkgs.gamescope-wsi ];
    };
}
