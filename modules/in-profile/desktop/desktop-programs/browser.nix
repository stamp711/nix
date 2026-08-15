{
  flake.homeModules.desktop-programs =
    { lib, pkgs, ... }:
    {
      home.packages = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) [ pkgs.google-chrome ];

      xdg.configFile."finicky/finicky.js" = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        text = ''
          export default ${
            builtins.toJSON {
              defaultBrowser = "Google Chrome:Default";
              handlers = [
                {
                  match = [
                    "*byted*/*"
                    "*feishu*/*"
                    "*larkoffice*/*"
                    "*tiktok-*/*"
                  ];
                  browser = "Google Chrome:Work";
                }
              ];
            }
          };
        '';
      };
    };

  flake.darwinModules.desktop-programs = {
    homebrew.casks = [
      "google-chrome"
      "finicky"
    ];
  };
}
