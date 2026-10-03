{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.bifrost = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "bifrost";
        version = "2.2.5";

        # Upstream's HTTP transport binary includes the web UI and is statically linked.
        src = pkgs.fetchurl {
          url = "https://downloads.getmaxim.ai/bifrost/v${finalAttrs.version}/linux/amd64/bifrost-http";
          sha256 = "a2ea1cb1537332cd47629e18a96775c0894925bf8603801b9f08de9f3c016980";
        };

        dontUnpack = true;
        dontStrip = true;
        dontPatchELF = true;
        installPhase = ''
          runHook preInstall
          install -Dm755 "$src" "$out/bin/bifrost-http"
          runHook postInstall
        '';

        doInstallCheck = true;
        installCheckPhase = ''
          runHook preInstallCheck
          "$out/bin/bifrost-http" -help
          runHook postInstallCheck
        '';

        meta = {
          description = "Bifrost LLM gateway with embedded web UI";
          homepage = "https://github.com/maximhq/bifrost";
          license = lib.licenses.asl20;
          sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
          platforms = [ "x86_64-linux" ];
          mainProgram = "bifrost-http";
        };
      });
    };
}
