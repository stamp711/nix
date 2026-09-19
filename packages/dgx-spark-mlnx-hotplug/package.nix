# Repackage NVIDIA's ConnectX-7 hotplug handler and udev rules for DGX Spark.
let
  platforms = [
    "aarch64-linux"
    "x86_64-linux"
  ];
in
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    {
      packages = lib.optionalAttrs (builtins.elem system platforms) {
        dgx-spark-mlnx-hotplug = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
          pname = "dgx-spark-mlnx-hotplug";
          version = "26.01-1";

          src = pkgs.fetchurl {
            url = "https://repo.download.nvidia.com/baseos/ubuntu/noble/arm64/pool/dgx/d/dgx-spark-mlnx-hotplug/${finalAttrs.pname}_${finalAttrs.version}_all.deb";
            hash = "sha256-LbHoe6LS56PavyHUbO07N+nTj9pRhDgAWAXb4E39zAE=";
          };

          strictDeps = true;
          dontBuild = true;

          nativeBuildInputs = [
            pkgs.dpkg
            pkgs.makeWrapper
          ];

          buildInputs = [ pkgs.bash ];

          unpackPhase = ''
            runHook preUnpack
            dpkg-deb --extract "$src" .
            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall

            install -Dm755 \
              opt/nvidia/dgx-spark-mlnx-hotplug/mtk-hotplug-handler.sh \
              "$out/libexec/dgx-spark-mlnx-hotplug/mtk-hotplug-handler.sh"
            install -Dm644 \
              lib/udev/rules.d/90-mtk-hotplug.rules \
              "$out/lib/udev/rules.d/90-mtk-hotplug.rules"
            install -Dm644 \
              usr/share/doc/dgx-spark-mlnx-hotplug/copyright \
              "$out/share/doc/dgx-spark-mlnx-hotplug/copyright"
            install -Dm644 \
              usr/share/doc/dgx-spark-mlnx-hotplug/changelog.Debian.gz \
              "$out/share/doc/dgx-spark-mlnx-hotplug/changelog.Debian.gz"

            patchShebangs "$out/libexec/dgx-spark-mlnx-hotplug/mtk-hotplug-handler.sh"
            substituteInPlace "$out/lib/udev/rules.d/90-mtk-hotplug.rules" \
              --replace-fail \
                "/opt/nvidia/dgx-spark-mlnx-hotplug/mtk-hotplug-handler.sh" \
                "$out/libexec/dgx-spark-mlnx-hotplug/mtk-hotplug-handler.sh"
            wrapProgram "$out/libexec/dgx-spark-mlnx-hotplug/mtk-hotplug-handler.sh" \
              --prefix PATH : ${
                lib.makeBinPath [
                  pkgs.coreutils
                  pkgs.gnugrep
                  pkgs.pciutils
                ]
              }

            runHook postInstall
          '';

          meta = {
            description = "ConnectX-7 hot-plug power management for NVIDIA DGX Spark";
            homepage = "https://docs.nvidia.com/dgx/dgx-spark/release-notes.html";
            license = lib.licenses.unfree;
            inherit platforms;
          };
        });
      };
    };
}
