{
  description = "Fail2ban intrusion prevention";

  module = {
    services.fail2ban = {
      enable = true;
      maxretry = 3;
      bantime = "10m";
      bantime-increment = {
        enable = true;
        maxtime = "48h";
      };
      ignoreIP = [
        "127.0.0.0/8"
        "::1"
      ];
    };
  };
}
