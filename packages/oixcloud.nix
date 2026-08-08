# Where oixcloud comes from: a macOS build off the releases, a Linux build that exists
# only inside their OCI image.
{ lib, ... }:
let
  version = "v0.0.29";
  # The value in the release's own SHA256SUMS.
  sha256 = "7bacde236d551a38ec6596b74fc77ea824e7e488fb8e5a3b1f03247c4b1581ff";
  # The Linux build, for hosts that run it as a container. NOTE: Still v0.0.28.
  imageDigest = "sha256:f1f219733cc19a502a59d4e27435e42475f66c4f19a3cdf986f3deac054ca329";
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
