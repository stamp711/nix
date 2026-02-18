{
  description = "Kubernetes tools";

  module =
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
