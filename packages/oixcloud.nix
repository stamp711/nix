# Upstream ships macOS builds only; the Linux one lives solely in their OCI image.
# Both are pinned here so the two move together.
{ lib, ... }:
let
  version = "v0.0.28";
  sha256 = "85448ebbe4255677ae03057d777cb6a81e07b8629e0ccf9ad9704c91d38196f6";
  # The Linux build, for hosts that run it as a container.
  imageDigest = "sha256:f1f219733cc19a502a59d4e27435e42475f66c4f19a3cdf986f3deac054ca329";
in
{
  flake.lib.oixcloudImage = "ghcr.io/pickrui/oixcloud-external-proxy-program@${imageDigest}";

  # Guard on system, not on pkgs: a shape that depends on pkgs makes perSystem recurse.
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
