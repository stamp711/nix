{
  flake.nixvimModules.default = {
    # [A]I is under group <leader>a
    extraConfigLua = ''
      require("which-key").add({
        { "<leader>a", group = "ai", mode = { "n", "v" } },
      })
    '';
  };
}
