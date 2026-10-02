{
  flake.homeModules.desktop-linux =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.google-chrome ];

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/http" = [ "google-chrome.desktop" ];
          "x-scheme-handler/https" = [ "google-chrome.desktop" ];
          "text/html" = [ "google-chrome.desktop" ];
          "application/xhtml+xml" = [ "google-chrome.desktop" ];
        };
      };
    };

  flake.darwinModules.desktop-darwin = {
    homebrew.casks = [
      "google-chrome"
      "finicky"
    ];
  };

  flake.homeModules.desktop-darwin = {
    xdg.configFile."finicky/finicky.js" = {
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
}
