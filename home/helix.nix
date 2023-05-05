{...}: {
  programs.helix.enable = true;
  programs.helix.settings = {
    theme = "monokai";
    editor.line-number = "relative";
    editor.auto-format = true;
    editor.true-color = true;
    editor.color-modes = true;
    editor.lsp.display-messages = true;
    editor.cursor-shape = {
      normal = "block";
      insert = "bar";
      select = "bar";
    };
    editor.whitespace.render = {tab = "all";};
  };
  programs.helix.languages = [
    {
      name = "yaml";
      formatter = {
        command = "prettier";
        args = ["--parser" "yaml"];
      };
      config.yaml.schemas = {Kubernetes = "*";};
    }
    {
      name = "nix";
      formatter.command = "alejandra";
    }
  ];
}
