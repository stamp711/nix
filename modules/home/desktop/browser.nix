{
  description = "Web browser";

  module =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.google-chrome ];
    };
}
