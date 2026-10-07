{ self, lib, ... }:
{
  flake.nixosModules = {

    # for RoCE
    # https://losslessnetwork.com/learn/host-networking/multi-rail-source-routing/#possible-values-cheat-sheet
    dgx-spark.boot.kernel.sysctl = {
      "net.ipv4.conf.enp1s0f0np0.arp_ignore" = 1;
      "net.ipv4.conf.enp1s0f0np0.arp_announce" = 2;
      "net.ipv4.conf.enP2p1s0f0np0.arp_ignore" = 1;
      "net.ipv4.conf.enP2p1s0f0np0.arp_announce" = 2;
    };

    dgx-spark.networking.networkmanager.ensureProfiles.profiles =
      lib.mapAttrs
        (_: connection: {
          connection = self.lib.mergeDisjoint [
            { type = "ethernet"; }
            connection
          ];
          ipv4.method = "manual";
          ipv6.method = "disabled";
        })
        {
          # Both PCIe paths of QSFP port 0, nearest the Ethernet port.
          qsfp0-P0 = {
            id = "QSFP port 0, PCIe domain 0";
            interface-name = "enp1s0f0np0";
          };
          qsfp0-P2 = {
            id = "QSFP port 0, PCIe domain 2";
            interface-name = "enP2p1s0f0np0";
          };
        };

    spark-abbc.networking.networkmanager.ensureProfiles.profiles = {
      qsfp0-P0.ipv4.address1 = "10.0.20.1/24";
      qsfp0-P2.ipv4.address1 = "10.0.21.1/24";
    };

    spark-14f3.networking.networkmanager.ensureProfiles.profiles = {
      qsfp0-P0.ipv4.address1 = "10.0.20.2/24";
      qsfp0-P2.ipv4.address1 = "10.0.21.2/24";
    };

  };
}
