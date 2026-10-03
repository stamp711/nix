{
  flake.homeModules.cli-programs = {

    programs.codex = {
      enable = true;
      enableMcpIntegration = true;
      # Merge declared settings while allowing Codex to save runtime changes.
      mutableSettings = true;
      settings = {
        features.daemon_auto_start = false;
      };
    };

  };
}
