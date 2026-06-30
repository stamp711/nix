# treesitter-context: sticky scope (function/class/...) pinned at the top of the window.
{
  flake.nixvimModules.default = {

    plugins.treesitter-context = {
      enable = true;
      settings = {
        mode = "topline";
        multiwindow = true;
      };
    };

    # Post so the Snacks global already exists.
    extraConfigLuaPost = ''
      Snacks.toggle({
        name = "Treesitter Context",
        get = function() return require("treesitter-context").enabled() end,
        set = function(s) require("treesitter-context")[s and "enable" or "disable"]() end,
      }):map("<leader>ut")
    '';

  };
}
