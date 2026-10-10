{ lib, self, ... }:
{
  flake.overlays.workarounds = _: prev: {

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

    # 2026-10-10
    # TODO: remove once nixpkgs includes https://github.com/NixOS/nixpkgs/pull/569401.
    eternal-terminal = prev.eternal-terminal.overrideAttrs (
      old:
      assert lib.assertMsg (
        old.version == "7.0.0" && (old.patches or [ ]) == [ ]
      ) "eternal-terminal: upstream changed; remove/review the local PR #569401 workaround";
      {
        patches = [
          ./eternal-terminal-cmake-cxx-version.patch
          ./eternal-terminal-thread-pool-c++20-result-of.patch
        ];
        patchFlags = (old.patchFlags or [ "-p1" ]) ++ [
          "--fuzz=0"
          "--forward"
        ];
        env = builtins.removeAttrs (old.env or { }) [ "CXXFLAGS" ];
      }
    );

    # 2026-10-10
    # TODO: remove once nixpkgs includes https://github.com/NixOS/nixpkgs/pull/569719.
    contour = prev.contour.overrideAttrs (
      old:
      let
        expectedPatches = lib.optionals prev.stdenv.hostPlatform.isDarwin [
          "dont-fix-app-bundle.diff"
          "remove-deep-flag-from-codesign.diff"
        ];
      in
      assert lib.assertMsg (
        old.version == "0.6.3.8249"
        && map (patch: baseNameOf (toString patch)) (old.patches or [ ]) == expectedPatches
        && old.cmakeFlags == [ "-DCONTOUR_USE_CPM=OFF" ]
        && (old.postPatch or "") == ""
      ) "contour ${old.version}: upstream changed; remove or recheck the nixpkgs PR #569719 backport";
      {
        version = "0.7.0.8982";
        src = old.src.override {
          hash = "sha256-sY3qNaYsoYY6Ox5W7F2WHFHId89WbeGJ4fWs2PFQmNk=";
        };
        env = self.lib.mergeDisjoint [
          (old.env or { })
          (lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
            NIX_LDFLAGS = "-L${lib.getLib prev.llvmPackages.libcxx}/lib";
          })
        ];
        cmakeFlags = [
          "-DCONTOUR_USE_CPM=OFF"
        ]
        ++ lib.optionals prev.stdenv.hostPlatform.isDarwin [ "-DCONTOUR_MACOS_DEPLOY=OFF" ];
        patches = lib.optionals prev.stdenv.hostPlatform.isDarwin [
          ./contour-link-qtquick.patch
          ./contour-macos-deploy-toggle.patch
        ];
        patchFlags = (old.patchFlags or [ "-p1" ]) ++ [
          "--fuzz=0"
          "--forward"
        ];
        postFixup =
          (old.postFixup or "")
          + lib.optionalString prev.stdenv.hostPlatform.isDarwin ''
            /usr/bin/codesign --force --sign - $out/Applications/contour.app
          '';
      }
    );
    libunicode = prev.libunicode.overrideAttrs (
      old:
      assert lib.assertMsg (
        old.version == "0.9.0"
        &&
          map (patch: baseNameOf (toString patch)) (old.patches or [ ]) == [ "remove-target-properties.diff" ]
        && (old.postPatch or "") == ""
      ) "libunicode ${old.version}: upstream changed; remove or recheck the nixpkgs PR #569719 backport";
      {
        version = "0.9.3";
        src = old.src.override {
          hash = "sha256-teyo4KYVdS6+WIjOdS5p7fXZJoMQsL7lPugoaAQ07r4=";
        };
        patches = [ ];
      }
    );

  };
}
