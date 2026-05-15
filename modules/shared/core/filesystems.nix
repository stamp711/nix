{
  flake.nixosModules.core = {
    boot.supportedFilesystems = [ "ntfs" ];
  };
}
