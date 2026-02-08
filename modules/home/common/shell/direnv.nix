# direnv with nix-direnv integration
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
