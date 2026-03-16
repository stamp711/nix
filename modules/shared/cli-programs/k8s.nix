# Kubernetes tools
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        fluxcd
        kubectl
        kubectx
        kubernetes-helm
      ];
    };
}
