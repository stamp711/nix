{
  description = "1Password SSH agent integration";

  module =
    { config, ... }:
    {
      # Use 1Password SSH agent
      home.sessionVariables.SSH_AUTH_SOCK = "${config.home.homeDirectory}/.1password/agent.sock";
    };
}
