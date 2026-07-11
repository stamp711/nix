{
  flake.nixosModules.linux-gaming = {
    boot.kernelModules = [ "ntsync" ];
  };
}
