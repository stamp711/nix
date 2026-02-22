{
  description = "1Password desktop app";

  module =
    { pkgs, ... }:
    {
      home.packages = [ pkgs._1password-gui ];
    };
}
