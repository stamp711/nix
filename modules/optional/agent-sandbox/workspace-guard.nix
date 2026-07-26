# ~/code is the operator's; agents edit only their own jj workspace under ~/agents.
{
  flake.homeModules.agent-sandbox = {
    programs.claude-code.settings.permissions.deny = [ "Edit(~/code/**)" ];
  };
}
