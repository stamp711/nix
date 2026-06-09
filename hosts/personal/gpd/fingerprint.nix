# Fingerprint reader: FocalTech FT9362, USB 2808:0752 (GPD Pocket 4).
#
# Driven by the upstream OPEN-SOURCE match-on-host driver from libfprint MR !588
# (no proprietary blob). The branch currently registers only 2808:c652; we add
# our 0752 (the same FT9362 chip) to the driver's id_table. The driver reads the
# sensor geometry at runtime, so the PID line is expected to be all it needs.
#
#   Upstream MR: https://gitlab.freedesktop.org/libfprint/libfprint/-/merge_requests/588
#   Branch:      dtrunk90/libfprint @ focaltech-moh  (flake input `libfprint-focaltech`)
#   Track updates: `nix flake update libfprint-focaltech`
#
# TO REMOVE once MR !588 (including 0752) lands in nixpkgs' libfprint:
#   1. delete this file, its `imports` entry and module reference in ./default.nix
#   2. delete the `libfprint-focaltech` input from flake.nix
#   3. if upstream libfprint then covers 0752, just set `services.fprintd.enable = true;`
# While 0752 is not yet upstream, keep the id_table patch below even after the
# branch merges (it adds our specific PID).
{ inputs, ... }:
{
  flake.nixosModules.gpd-fingerprint =
    { pkgs, ... }:
    let
      libfprint-focaltech = pkgs.libfprint.overrideAttrs (old: {
        version = "1.94.10-focaltech-moh";
        src = inputs.libfprint-focaltech;

        # The branch ships the FT9362 driver registered for c652 only; add 0752.
        # --replace-fail so we notice if upstream changes the id_table layout.
        postPatch = (old.postPatch or "") + ''
          substituteInPlace libfprint/drivers/focaltech.c \
            --replace-fail \
              '{ .vid = 0x2808, .pid = 0xc652 },' \
              '{ .vid = 0x2808, .pid = 0xc652 },
            { .vid = 0x2808, .pid = 0x0752 },'

          # The branch execs a test script at meson configure time, but the
          # sandbox has no /usr/bin/env and upstream's bare `patchShebangs` runs
          # in --host mode (skipping the python3 build tool), leaving those scripts
          # with `#!/usr/bin/env python3`. Point them at the build python3 directly.
          for f in tests/*.py examples/*.py; do
            substituteInPlace "$f" --replace-quiet '/usr/bin/env python3' '${pkgs.python3.interpreter}'
          done
        '';

        # WIP branch carries device-dependent capture tests; don't gate the build on them.
        doCheck = false;
        doInstallCheck = false;
      });

      fprintd = pkgs.fprintd.override { libfprint = libfprint-focaltech; };
    in
    {
      services.fprintd = {
        enable = true;
        package = fprintd;
      };

      # Match-on-host driver enrolled templates
      my.persistence.directories = [ "/var/lib/fprint" ];

      # Mark 0752 autosuspend-safe, as upstream libfprint's hwdb does for the rest
      # of the FT9362 family (it lists c652 but not our 0752 yet).
      services.udev.extraHwdb = ''
        usb:v2808p0752*
         ID_AUTOSUSPEND=1
         ID_PERSIST=0
      '';
    };
}
