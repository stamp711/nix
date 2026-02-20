{
  description = "Direnv with nix-direnv integration & mise";

  module = {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      mise.enable = true;
    };
    programs.mise.enable = true;
  };
}
