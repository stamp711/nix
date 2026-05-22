{
  flake.nixosModules.linux-gaming =
    { pkgs, ... }:
    {
      services.wivrn = {
        enable = true;
        # package = pkgs.wivrn.override { cudaSupport = true; }; # override moved to NUC hardware.nix
        autoStart = true;
        openFirewall = true;
        highPriority = true;
        steam.importOXRRuntimes = true;
        config = {
          enable = true;
          json = {
            bit-depth = 10;
            application = [ pkgs.wayvr ];
            hid-forwarding = true;
          };
        };
      };
      programs.alvr = {
        enable = true;
        openFirewall = true;
      };
    };

  flake.homeModules.linux-gaming =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = [ pkgs.xrizer ];

      # Register xrizer as the OpenVR runtime so OpenVR games forward through
      # xrizer ➡️ OpenXR ➡️ WiVRn instead of looking for SteamVR.
      # Installed as a mutable file (not xdg.configFile) so SteamVR can rewrite
      # it; rebuild restores xrizer.
      home.activation.openvrpaths = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run install -Dm644 ${
          pkgs.writeText "openvrpaths.vrpath" (
            builtins.toJSON {
              version = 1;
              jsonid = "vrpathreg";
              external_drivers = null;
              config = [ "${config.xdg.dataHome}/Steam/config" ];
              log = [ "${config.xdg.dataHome}/Steam/logs" ];
              runtime = [ "${pkgs.xrizer}/lib/xrizer" ];
            }
          )
        } "$HOME/.config/openvr/openvrpaths.vrpath"
      '';
    };
}
