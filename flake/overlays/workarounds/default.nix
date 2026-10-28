{
  flake.overlays.workarounds = _: prev: {

    # 2026-10-28
    # The bundled Codex catalog now sets multi_agent_version to "v2".
    # TODO: remove once CLIProxyAPI's preservation test matches its catalog.
    cli-proxy-api = prev.cli-proxy-api.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace sdk/api/handlers/openai/codex_client_models_test.go \
          --replace-fail 'if !exists || value != nil {' 'if !exists || value != "v2" {' \
          --replace-fail 'want preserved null' 'want preserved v2'
      '';
    });

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
