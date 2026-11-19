{
  flake.overlays.workarounds = _: prev: {

    # 2026-10-22
    # deal needs docstring-parser's source fixtures and support for pytest.param cases.
    # TODO: remove once nixpkgs fixes deal's docstring-parser test integration.
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (_: pythonPrev: {
        deal = pythonPrev.deal.overridePythonAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace tests/test_linter/test_extractors/test_exceptions.py \
              --replace-fail \
                "root = Path(docstring_parser.__path__[0]) / 'tests'" \
                "root = Path('${pythonPrev.docstring-parser.src}/docstring_parser/tests')" \
              --replace-fail \
                "assert isinstance(case, astroid.Tuple)" \
                "assert isinstance(case, (astroid.Tuple, astroid.Call))" \
              --replace-fail \
                "given = case.elts[0]" \
                "given = case.args[0] if isinstance(case, astroid.Call) else case.elts[0]" \
              --replace-fail \
                "if not isinstance(given, astroid.Const):" \
                "if not isinstance(given, astroid.Const) or not isinstance(given.value, str):"
          '';
        });
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
        # Rebased for 0.46.0's terminal teardown and live-view cursor handling.
        ./zellij-cursor-color.patch
      ];
      patchFlags = (old.patchFlags or [ "-p1" ]) ++ [ "--fuzz=0" ];
    });

  };
}
