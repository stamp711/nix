{
  flake.homeModules.cli-programs = {

    programs.codex = {
      enable = true;
      enableMcpIntegration = true;
      # Merge declared settings while allowing Codex to save runtime changes.
      mutableSettings = true;
      settings = {
        approvals_reviewer = "auto_review";
        features.daemon_auto_start = false;
      };
    };

  };
}
