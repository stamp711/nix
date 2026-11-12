# Where oixcloud comes from: a macOS build off the releases, a Linux build that exists
# only inside their OCI image.
{ lib, ... }:
let
  version = "v0.0.67";
  # The value in the release's own SHA256SUMS.
  sha256 = "befb6f7e1a06529db9a5a50862f3a8c809505852bcaf3deaaf47323a9c218779";
  # The Linux build, for hosts that run it as a container.
  imageDigest = "sha256:1a118d10d4acd1768a2b3903683631210d313b0273e296330a8b671badb7903a";
in
{
  flake.lib.oixcloudImage = "ghcr.io/pickrui/oixcloud-external-proxy-program@${imageDigest}";

  # Guarded on system: reading pkgs to decide the shape makes perSystem recurse.
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "aarch64-darwin") {
      packages.oixcloud = pkgs.stdenv.mkDerivation {
        pname = "oixcloud-external-proxy-program";
        inherit version;

        src = pkgs.fetchurl {
          url = "https://github.com/pickrui/oixcloud-external-proxy-program/releases/download/${version}/oixcloud-external-proxy-program-arm64";
          inherit sha256;
        };

        dontUnpack = true;
        dontStrip = true; # Signed by the vendor; stripping would break LC_CODE_SIGNATURE.
        installPhase = "install -Dm755 $src $out/bin/oixcloud-external-proxy-program";

        meta = {
          description = "oixCloud external-proxy helper";
          homepage = "https://github.com/pickrui/oixcloud-external-proxy-program";
          # No license published.
          license = pkgs.lib.licenses.unfree;
          platforms = [ "aarch64-darwin" ];
          mainProgram = "oixcloud-external-proxy-program";
        };
      };
    };
}
