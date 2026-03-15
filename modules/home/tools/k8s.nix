# Kubernetes tools
{
  flake.homeModules.tools =
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
