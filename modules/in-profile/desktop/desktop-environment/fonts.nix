# Fonts including Nerd Font for terminal icons
{ inputs, ... }:
{
  flake.homeModules.desktop-environment =
    { pkgs, ... }:
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
      fonts.fontconfig.enable = true;
      home.packages = [
        monaco
        monaco-nerd-font
      ];
    };

  flake.nixosModules.desktop-environment =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        source-han-sans
        source-han-serif
        sarasa-gothic
        lxgw-wenkai
      ];
      # fontconfig's upstream 65-nonlatin.conf lists SimSun/WenQuanYi/etc.
      # for Han fallback but not Source Han / Noto CJK, so without explicit
      # rules fc-match sans-serif:lang=zh-cn returns DejaVu (no CJK glyphs).
      fonts.fontconfig.localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <match target="pattern">
            <test name="lang" compare="contains"><string>zh</string></test>
            <test name="family"><string>sans-serif</string></test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Source Han Sans SC</string>
            </edit>
          </match>
          <match target="pattern">
            <test name="lang" compare="contains"><string>zh</string></test>
            <test name="family"><string>serif</string></test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Source Han Serif SC</string>
            </edit>
          </match>
          <match target="pattern">
            <test name="lang" compare="contains"><string>zh</string></test>
            <test name="family"><string>monospace</string></test>
            <edit name="family" mode="prepend" binding="strong">
              <string>Sarasa Mono SC</string>
            </edit>
          </match>
        </fontconfig>
      '';
    };
}
