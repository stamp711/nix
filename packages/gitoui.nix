{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.gitoui = pkgs.rustPlatform.buildRustPackage {
        pname = "gitoui";
        version = inputs.gitoui.shortRev or "dirty";
        src = inputs.gitoui;
        cargoLock.lockFile = "${inputs.gitoui}/Cargo.lock";
        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.oniguruma ];
        doCheck = false;
        meta.mainProgram = "gitoui";
      };
    };
}
