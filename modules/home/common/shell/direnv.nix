{
  description = "Direnv with nix-direnv integration";

  module = {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
