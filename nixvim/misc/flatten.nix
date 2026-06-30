# flatten.nvim: open files from the embedded terminal here instead of nesting nvim.
{
  flake.nixvimModules.default = { pkgs, ... }: {

    extraPlugins = [ pkgs.vimPlugins.flatten-nvim ];

    # Pre so the guest forwards to this instance before other plugins set up.
    extraConfigLuaPre = ''
      require("flatten").setup({
        block_for = { gitcommit = true, gitrebase = true, jjdescription = true },
        window = { open = "alternate" }, -- open in the editor window, not the terminal split
      })
    '';

  };
}
