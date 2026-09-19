# Bind mounts keeping the D: drive library's Proton prefixes and shader cache off NTFS.
# NTFS windows_names can't hold dosdevices/c:
{
  flake.nixosModules.nuc =
    { config, ... }:
    let
      user = config.my.primaryUser;
      group = config.users.users.${user}.group;

      library = "/mnt/d/SteamLibrary/steamapps";

      compatdata = "/var/lib/steam/compatdata";
      shadercache = "/var/lib/steam/shadercache";
    in
    {
      my.persistence.directories = [
        {
          directory = compatdata;
          inherit user group;
          mode = "0755";
        }
        {
          directory = shadercache;
          inherit user group;
          mode = "0755";
        }
      ];

      fileSystems = {
        "${library}/compatdata" = {
          device = compatdata;
          fsType = "none";
          options = [
            "bind"
            "nofail"
          ];
          depends = [
            "/mnt/d"
            compatdata
          ];
        };
        "${library}/shadercache" = {
          device = shadercache;
          fsType = "none";
          options = [
            "bind"
            "nofail"
          ];
          depends = [
            "/mnt/d"
            shadercache
          ];
        };
      };
    };
}
