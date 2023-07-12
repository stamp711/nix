{pkgs, ...}: {
  programs.vscode.enable = true;
  programs.vscode.enableUpdateCheck = false;
  programs.vscode.enableExtensionUpdateCheck = false;
  programs.vscode.mutableExtensionsDir = false;
  programs.vscode.extensions =
    (with pkgs.vscode-extensions; [
      brettm12345.nixfmt-vscode
      eamodio.gitlens
      github.copilot
      github.github-vscode-theme
      jnoortheen.nix-ide
      llvm-vs-code-extensions.vscode-clangd
      mhutchie.git-graph
      mkhl.direnv
      ms-azuretools.vscode-docker
      ms-vscode.cmake-tools
      ms-vscode-remote.remote-ssh
      redhat.vscode-yaml
      rust-lang.rust-analyzer
      serayuzgur.crates
      tamasfe.even-better-toml
      # vadimcn.vscode-lldb error on darwin
      vscodevim.vim
      wakatime.vscode-wakatime
      zxh404.vscode-proto3
    ])
    ++ (with pkgs.vscode-marketplace; [
      alefragnani.separators
      monokai.theme-monokai-pro-vscode
      ms-vscode-remote.remote-containers
      jscearcy.rust-doc-viewer
      lumiknit.parchment
      odiriuss.rust-macro-expand
      rescuetime.rescuetime
    ]);
  programs.vscode.userSettings = {
    "clangd.arguments" = ["-log=verbose" "-pretty" "--background-index"];
    "cmake.buildDirectory" = "\${workspaceFolder}/build/\${buildKit}/\${buildType}";
    "cmake.copyCompileCommands" = "\${workspaceFolder}/compile_commands.json";
    "diffEditor.ignoreTrimWhitespace" = false;
    "editor.accessibilitySupport" = "off";
    "editor.cursorBlinking" = "solid";
    "editor.fontFamily" = "UbuntuMono Nerd Font, Menlo, Monaco, 'Courier New', monospace, Hack Nerd Font";
    "editor.fontSize" = 14;
    "editor.formatOnSave" = true;
    "editor.inlineSuggest.enabled" = true;
    "editor.lineNumbers" = "relative";
    "editor.scrollBeyondLastLine" = false;
    "gitlens.telemetry.enabled" = false;
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nil";
    "[nix]"."editor.defaultFormatter" = "brettm12345.nixfmt-vscode";
    "redhat.telemetry.enabled" = false;
    "security.workspace.trust.enabled" = false;
    "separators.enabledSymbols" = [
      "Classes"
      "Constructors"
      "Enums"
      # "Functions"
      "Interfaces"
      # "Methods"
      "Namespaces"
      "Structs"
    ];
    "telemetry.telemetryLevel" = "off";
    # "workbench.colorTheme" = "Visual Studio Light";
    # "workbench.colorTheme" = "Default Dark+ Experimental";
    # "workbench.colorTheme" = "Monokai Pro";
    "workbench.colorTheme" = "GitHub Dark Default";
    "workbench.colorCustomizations" = {
      # "editor.background" = "#FFFFEA";
      "editorInlayHint.background" = "#00000000";
      "editorInlayHint.foreground" = "#BBBBBBFF";
    };
  };
}
