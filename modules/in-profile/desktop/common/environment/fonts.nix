# Fonts including Nerd Font for terminal icons
{
  flake.homeModules.desktop =
    { pkgs, ... }:
    {
      fonts.fontconfig.enable = true;
      home.packages = [
        pkgs.my.monaco
        pkgs.my.monaco-nerd-font
      ];
    };

  flake.nixosModules.desktop-linux =
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
