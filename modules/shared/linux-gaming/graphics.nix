{
  flake.nixosModules.linux-gaming = {
    # 32-bit driver stack for 32-bit Wine/Proton processes and 32-bit native games.
    hardware.graphics.enable32Bit = true;
  };
}
