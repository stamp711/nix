# GUI code editor
{ pkgs, ... }:
{
  programs.zed-editor = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.brewCasks.zed else pkgs.zed-editor;
    installRemoteServer = true;
    extensions = [
      "zed-wakatime"
      "nix"
      "xy-zed"
      "cyan-light-theme"
    ];
    # userSettings = { };
  };
}
