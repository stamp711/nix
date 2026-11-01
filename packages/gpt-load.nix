{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.gpt-load = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "gpt-load";
        version = "2.0.0-rc.58";

        # Upstream's static binary includes the web UI.
        src = pkgs.fetchurl {
          url = "https://github.com/tbphp/gpt-load/releases/download/v${finalAttrs.version}/gpt-load-linux-amd64";
          sha256 = "9aa4255a96f18dfc7c47dfd4fae809186b137a095a846bec7f2e38dafb4e828d";
        };

        dontUnpack = true;
        dontBuild = true;
        dontStrip = true;
        dontPatchELF = true;
        installPhase = ''
          runHook preInstall
          install -Dm755 "$src" "$out/bin/gpt-load"
          runHook postInstall
        '';

        meta = {
          description = "GPT-Load AI gateway with embedded web UI";
          homepage = "https://github.com/tbphp/gpt-load";
          license = lib.licenses.mit;
          sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
          platforms = [ "x86_64-linux" ];
          mainProgram = "gpt-load";
        };
      });
    };
}
