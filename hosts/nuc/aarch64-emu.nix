{
  flake.nixosModules.nuc = {
    boot.binfmt = {
      emulatedSystems = [ "aarch64-linux" ];
      # Keep QEMU available inside container mount namespaces.
      preferStaticEmulators = true;
    };
  };
}
