{
  description = "Base SSH configuration";

  module = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
    };
  };
}
