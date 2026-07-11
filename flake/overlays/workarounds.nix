{ lib, ... }: {
  flake.overlays.workarounds = _: prev: {

    # 2026-07-11
    # dpcontracts' README doctest calls asyncio.get_event_loop() (removed in
    # python 3.14); reaches us via nix-alien -> pylddwrap -> icontract.
    # TODO: remove once upstream patches the doctest (nixpkgs#539321 adds a
    # patch file, so old.patches stops being empty).
    pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
      (_: pyprev: {
        dpcontracts = pyprev.dpcontracts.overridePythonAttrs (
          old:
          lib.throwIf (
            (old.patches or [ ]) != [ ]
          ) "dpcontracts override obsolete: nixpkgs#539321 landed, remove it" { doCheck = false; }
        );
      })
    ];

    # 2026-07-11
    # starship's notify feature links mac-notification-sys, which crashes classic ld64
    # on aarch64-darwin; link with ld64.lld.
    # TODO: remove when nixpkgs#540463 lands.
    starship = prev.starship.overrideAttrs (
      old:
      lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin (
        lib.throwIf (old.env or { } ? NIX_CFLAGS_LINK)
          "starship override obsolete: nixpkgs#540463 landed, remove it"
          {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.llvmPackages.lld ];
            env = (old.env or { }) // {
              NIX_CFLAGS_LINK = "-fuse-ld=${lib.getExe' prev.llvmPackages.lld "ld64.lld"}";
            };
          }
      )
    );

  };
}
