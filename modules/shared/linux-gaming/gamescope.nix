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
      # WSI Vulkan layer for HDR + frame pacing under gamescope; 32-bit
      # variant needed for older Steam games. Jovian-NixOS pattern.
      hardware.graphics.extraPackages = [ pkgs.gamescope-wsi ];
      hardware.graphics.extraPackages32 = [ pkgs.pkgsi686Linux.gamescope-wsi ];

      # mangoapp for `gamescope --mangoapp`; gamescope runs on host so
      # needs the binary on host PATH (Steam FHS doesn't reach gamescope).
      environment.systemPackages = [ pkgs.mangohud ];
    };
}
