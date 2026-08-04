{
  perSystem =
    { pkgs, lib, ... }:
    let
      lock = lib.importJSON ./package-lock.json;
    in
    {
      packages.even-terminal = pkgs.buildNpmPackage rec {
        pname = "even-terminal";
        version = "0.8.1";

        src = pkgs.fetchurl {
          url = "https://registry.npmjs.org/@evenrealities/even-terminal/-/even-terminal-${version}.tgz";
          hash = "sha512-7g+xfe2nyv1wsNUQPqn1yz12R17Zv6w4PODKYIx+vkipNr7rpMVgjDUNFYLLNeOQWi2KT8ZJK81DL6jePYPmQA==";
        };

        # Upstream ships no lock; this one is ours.
        postPatch = "cp ${./package-lock.json} package-lock.json";

        # npmDepsHash would be per-system: 61 os/cpu-gated deps.
        npmDeps = pkgs.importNpmLock {
          packageLock = lock;
          package = lock.packages."";
        };
        npmConfigHook = pkgs.importNpmLock.npmConfigHook;

        dontNpmBuild = true;

        # The install hook mishandles scoped names.
        installPhase = ''
          runHook preInstall
          dest=$out/lib/node_modules/@evenrealities/even-terminal
          mkdir -p "$dest" $out/bin
          cp -r package.json bin dist node_modules "$dest/"
          patchShebangs "$dest/bin/cli.js"
          ln -s "$dest/bin/cli.js" $out/bin/even-terminal
          runHook postInstall
        '';

        meta = {
          description = "Even Terminal — AI coding CLI on smart glasses";
          homepage = "https://www.npmjs.com/package/@evenrealities/even-terminal";
          # No license published.
          license = pkgs.lib.licenses.unfree;
          mainProgram = "even-terminal";
        };
      };
    };
}
