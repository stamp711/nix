{
  flake.homeModules.cli-programs = {

    programs.codex = {
      enable = true;
      enableMcpIntegration = true;
      # Merge declared settings while allowing Codex to save runtime changes.
      mutableSettings = true;
      settings = {
        tui.theme = "base16-256"; # Use the terminal's Base16 palette, including slots 16–21.
      };
    };

  };
}
