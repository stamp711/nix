# zk: notebook-aware note-taking, under <leader>z. zk-nvim drives the zk CLI's own LSP server.
{
  flake.nixvimModules.default = {

    plugins.zk = {
      enable = true; # bakes the zk binary via the module's `zk` dependency
      settings = {
        picker = "snacks_picker";
        # zk-nvim starts its own client, so it misses the capabilities wrapper nixvim applies
        # to `lsp.servers.*`. Hand it blink-cmp's capabilities on top of neovim's defaults.
        lsp.config.capabilities.__raw = ''require("blink.cmp").get_lsp_capabilities(nil, true)'';
      };
    };

    extraConfigLua = ''
      require("which-key").add({
        { "<leader>z", group = "zk", mode = { "n", "x" } },
      })
    '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>zn";
        action = "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>";
        options.desc = "New Note";
      }
      {
        mode = "n";
        key = "<leader>zo";
        action = "<Cmd>ZkNotes { sort = { 'modified' } }<CR>";
        options.desc = "Notes";
      }
      {
        mode = "n";
        key = "<leader>zf";
        action = "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>";
        options.desc = "Search Notes";
      }
      {
        mode = "n";
        key = "<leader>zt";
        action = "<Cmd>ZkTags<CR>";
        options.desc = "Tags";
      }
      {
        mode = "n";
        key = "<leader>zb";
        action = "<Cmd>ZkBacklinks<CR>";
        options.desc = "Backlinks";
      }
      {
        mode = "n";
        key = "<leader>zl";
        action = "<Cmd>ZkLinks<CR>";
        options.desc = "Links";
      }
      {
        mode = "n";
        key = "<leader>zi";
        action = "<Cmd>ZkInsertLink<CR>";
        options.desc = "Insert Link";
      }
      {
        mode = "n";
        key = "<leader>zc";
        action = "<Cmd>ZkCd<CR>";
        options.desc = "Cd to Notebook";
      }

      # ZkMatch falls back to the word under the cursor; the selection variants need the range.
      {
        mode = "x";
        key = "<leader>zf";
        action = ":'<,'>ZkMatch<CR>";
        options.desc = "Search Notes (selection)";
      }
      {
        mode = "x";
        key = "<leader>zn";
        action = ":'<,'>ZkNewFromTitleSelection<CR>";
        options.desc = "New Note from Selection";
      }
      {
        mode = "x";
        key = "<leader>zi";
        action = ":'<,'>ZkInsertLinkAtSelection<CR>";
        options.desc = "Insert Link at Selection";
      }
    ];
  };
}
