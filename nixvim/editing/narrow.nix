# NrrwRgn: narrow a selection into its own buffer for focused (zen) editing.
{
  flake.nixvimModules.default =
    { pkgs, ... }:
    {
      extraPlugins = [ pkgs.vimPlugins.NrrwRgn ];

      globals.nrrw_rgn_nomap_nr = 1; # bind it ourselves instead of the default <Leader>nr

      keymaps = [
        {
          mode = "x";
          key = "<leader>N";
          action = "<Plug>NrrwrgnDo";
          options = {
            remap = true; # <Plug> needs a recursive map
            desc = "Narrow Region";
          };
        }
      ];
    };
}
