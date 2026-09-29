{ lib, ... }:
{
  flake.overlays.workarounds = _: prev: {

    # 2026-08-16
    # plumbum's test_pgrep asserts pgrep finds a running python, and a darwin
    # build has none; reaches us via pwntools -> rpyc -> plumbum.
    # TODO: remove once nixpkgs deselects it too.
    pythonPackagesExtensions =
      (prev.pythonPackagesExtensions or [ ])
      ++ lib.optionals prev.stdenv.hostPlatform.isDarwin [
        (_: pyprev: {
          plumbum = pyprev.plumbum.overridePythonAttrs (
            old:
            let
              # The pattern nixpkgs already uses for this package.
              deselect = "--deselect=tests/test_local.py::TestLocalMachine::test_pgrep";
            in
            lib.throwIf (old.version != "2.0.2" || lib.elem deselect old.pytestFlags)
              "plumbum ${old.version}: recheck test_pgrep"
              {
                pytestFlags = old.pytestFlags ++ [ deselect ];
              }
          );
        })
      ];

    # 2026-09-24
    # nixpkgs installs Nsight Compute's host/, target/ and sections/ dirs under bin/,
    # so bin/host shadows host(1) in every buildEnv. Expose the launchers only.
    # TODO: remove once nixpkgs moves them out of bin/.
    cudaPackages = prev.cudaPackages.overrideScope (
      _: cprev: {
        nsight_compute =
          prev.runCommand cprev.nsight_compute.name { inherit (cprev.nsight_compute) meta; }
            ''
              [ -d ${cprev.nsight_compute}/bin/host ] || { echo "nsight_compute: bin/host is gone, drop this workaround" >&2; exit 1; }
              mkdir -p $out/bin
              ln -s ${cprev.nsight_compute}/bin/ncu{,-ui} $out/bin/
            '';
      }
    );

    # 2026-09-29
    # Forward pane cursor colors (OSC 12/112) so Neovim can use its themed cursor.
    # TODO: remove once nixpkgs includes https://github.com/zellij-org/zellij/pull/5457.
    zellij-unwrapped = prev.zellij-unwrapped.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        (prev.fetchpatch {
          url = "https://github.com/zellij-org/zellij/commit/5b598e1f62aa3afc88231d537290d825c9a49806.patch";
          # 0.45.1 lacks this field; remove its context line from the reset hunk.
          decode = "(sed '/^         self\\.osc7_payload = None;$/d' | recountdiff)";
          hash = "sha256-Q54JqdDAiHKaGvGltFRdLfofT/YvOtrD9/pvgBhMUAM=";
        })
      ];
    });

  };
}
