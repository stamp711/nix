{
  description = "NetworkManager with wifi powersave and firewall";

  module = {
    networking = {
      networkmanager = {
        enable = true;
        wifi.powersave = true;
      };
      firewall.enable = true;
    };
  };
}
