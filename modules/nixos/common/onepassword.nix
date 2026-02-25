{
  description = "1Password password manager with SSH agent";

  module =
    { config, lib, ... }:
    {
      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
        polkitPolicyOwners = builtins.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users);
      };

      # Point SSH_AUTH_SOCK to 1Password SSH agent
      environment.sessionVariables.SSH_AUTH_SOCK = "\${HOME}/.1password/agent.sock";
    };
}
