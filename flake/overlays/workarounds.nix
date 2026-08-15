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

  };
}
