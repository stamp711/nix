# Motion habits: hardtime blocks jk spam, precognition hints the better motion.
{
  flake.nixvimModules.default = {

    plugins.hardtime = {
      enable = true;
      settings = {
        disable_mouse = false; # keep the mouse
        # h/l belong to nvim-origami, hardtime breaks it.
        restricted_keys = {
          h.__raw = "false";
          l.__raw = "false";
        };
        disabled_keys = {
          "<Up>".__raw = "false";
          "<Down>".__raw = "false";
          "<Left>".__raw = "false";
          "<Right>".__raw = "false";
        };
      };
    };

    plugins.precognition = {
      enable = true;
      settings.startVisible = false;
    };

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

    # Post for the Snacks global. precognition exposes no visibility getter, so track it.
    extraConfigLuaPost = ''
      Snacks.toggle({
        name = "Hardtime",
        get = function() return require("hardtime").is_plugin_enabled end,
        set = function(s) require("hardtime")[s and "enable" or "disable"]() end,
      }):map("<leader>uH")

      local precognition_visible = true
      Snacks.toggle({
        name = "Precognition",
        get = function() return precognition_visible end,
        set = function(s)
          precognition_visible = s
          require("precognition")[s and "show" or "hide"]()
        end,
      }):map("<leader>uP")
    '';

  };
}
