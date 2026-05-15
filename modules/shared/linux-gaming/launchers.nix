{
  flake.homeModules.linux-gaming =
    { pkgs, ... }:
    {
      programs.lutris.enable = true;
      programs.mangohud.enable = true;

      home.packages = with pkgs; [
        cartridges
        umu-launcher
      ];
    };
}
