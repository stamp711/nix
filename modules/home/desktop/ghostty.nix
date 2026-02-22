{
  description = "Ghostty terminal emulator";

  module = {
    programs.ghostty = {
      enable = true;
      settings = {
        font-family = "Monaco Nerd Font";
      };
    };
  };
}
