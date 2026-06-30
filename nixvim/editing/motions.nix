# Motion habits: hardtime blocks hjkl/arrow spam, precognition hints the better motion.
{
  flake.nixvimModules.default = {

    plugins.hardtime = {
      enable = true;
      settings.disable_mouse = false; # keep the mouse
    };

    plugins.precognition = {
      enable = true;
      settings.startVisible = false;
    };

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
