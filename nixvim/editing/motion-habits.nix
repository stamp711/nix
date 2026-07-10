# Motion habits: hardtime blocks jk spam, precognition hints the better motion.
{
  flake.nixvimModules.default = {

    plugins.precognition = {
      enable = true;
      settings.startVisible = false;
    };

    # Post for the Snacks global. precognition exposes no visibility getter, so track it.
    extraConfigLuaPost = ''
      local precognition_visible = false;
      Snacks.toggle({
        name = "Precognition",
        get = function() return precognition_visible end,
        set = function(s)
          precognition_visible = s
          require("precognition")[s and "show" or "hide"]()
        end,
      }):map("<leader>uP")
    '';

    # <C-d>/<C-u>: half-screen is too jumpy, use a 10-line step.
    keymaps =
      let
        step = "10";
      in
      [
        {
          key = "<C-d>";
          mode = "n";
          action = "${step}<C-d>";
          options.desc = "Scroll down";
        }
        {
          key = "<C-u>";
          mode = "n";
          action = "${step}<C-u>";
          options.desc = "Scroll up";
        }
      ];

  };
}
