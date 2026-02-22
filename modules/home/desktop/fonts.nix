{
  description = "Fonts including Nerd Font for terminal icons";

  module =
    { inputs, pkgs, ... }:
    let
      monaco = pkgs.stdenv.mkDerivation {
        pname = "monaco";
        version = "0.2.1";
        src = inputs.monaco;
        installPhase = ''
          mkdir -p $out/share/fonts/truetype
          find $src -name '*.ttf' -exec cp {} $out/share/fonts/truetype/ \;
        '';
      };
      monaco-nerd-font = pkgs.stdenv.mkDerivation {
        pname = "monaco-nerd-font";
        version = "0.2.1";
        src = inputs.monaco;
        nativeBuildInputs = [ pkgs.nerd-font-patcher ];
        buildPhase = ''
          mkdir -p patched
          for f in $(find $src -name '*.ttf'); do
            nerd-font-patcher --complete --no-progressbars -out patched "$f"
          done
        '';
        installPhase = ''
          mkdir -p $out/share/fonts/truetype
          cp patched/*.ttf $out/share/fonts/truetype/
        '';
      };
    in
    {
      home.packages = [
        monaco
        monaco-nerd-font
      ];

      fonts.fontconfig.enable = true;
    };
}
