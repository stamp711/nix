{
  description = "GUI code editor";

  module =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.zed-editor ];
    };
}
