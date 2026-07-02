# mini.animate: smooth <C-d>/<C-u> scrolling.
{
  flake.nixvimModules.default = {
    plugins.mini-animate = {
      enable = true;

      # suppress animation on mouse-wheel scroll (LazyVim's trick)
      luaConfig.pre = ''
        local mouse_scrolled = false
        for _, scroll in ipairs({ "Up", "Down" }) do
          local key = "<ScrollWheel" .. scroll .. ">"
          vim.keymap.set({ "", "i" }, key, function()
            mouse_scrolled = true
            return key
          end, { expr = true })
        end
        _G.__mini_animate_scroll = function()
          if mouse_scrolled then mouse_scrolled = false; return false end
          return true
        end
      '';

      settings = {
        cursor.enable = false;
        resize.enable = false;
        open.enable = false;
        close.enable = false;
        scroll = {
          timing.__raw = ''require("mini.animate").gen_timing.quadratic({ duration = 150, unit = "total", easing = "out" })'';
          subscroll.__raw = ''
            require("mini.animate").gen_subscroll.equal({
              predicate = function(total_scroll)
                if not _G.__mini_animate_scroll() then return false end
                return total_scroll > 1
              end,
            })
          '';
        };
      };
    };

    # <leader>ua toggle; Post so the Snacks global exists
    extraConfigLuaPost = ''
      Snacks.toggle({
        name = "Mini Animate",
        get = function() return not vim.g.minianimate_disable end,
        set = function(state) vim.g.minianimate_disable = not state end,
      }):map("<leader>ua")
    '';
  };
}
