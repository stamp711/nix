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

      # gnome-control-center only shows the "Fingerprint Login" row when it can
      # read org.gnome.login-screen/enable-fingerprint-authentication (see
      # cc-user-page.c:update_fingerprint_row_state). That schema ships with GDM,
      # which we don't run (greetd), so the row stays hidden even though fprintd
      # works. Install just the schema (no gdm in the closure) so Settings shows it.
      loginScreenSchema = pkgs.runCommandLocal "gnome-login-screen-schema" { } ''
        install -Dm444 \
          ${pkgs.gdm}/share/gsettings-schemas/*/glib-2.0/schemas/org.gnome.login-screen.gschema.xml \
          -t $out/share/glib-2.0/schemas
        ${pkgs.glib.dev}/bin/glib-compile-schemas $out/share/glib-2.0/schemas
      '';
    in
    {
      services.fprintd = {
        enable = true;
        package = fprintd;
      };

      # fprintd: enrollment/verification CLI (fprintd-enroll, -verify, -list).
      # loginScreenSchema: makes GNOME Settings expose the fingerprint UI (above).
      environment.systemPackages = [
        fprintd
        loginScreenSchema
      ];

      # Match-on-host driver enrolled templates
      my.persistence.directories = [ "/var/lib/fprint" ];

      # FocalTech sensors misbehave under USB autosuspend; keep this one powered.
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2808", ATTR{idProduct}=="0752", ATTR{power/control}="on", ATTR{power/autosuspend}="-1"
      '';
    };
}
