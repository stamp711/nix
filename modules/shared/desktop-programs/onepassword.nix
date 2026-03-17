{
  flake.nixosModules.desktop-programs =
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

  # Symlink 1Password SSH agent socket over the system SSH agent socket on macOS
  flake.darwinModules.desktop-programs =
    { config, ... }:
    {
      launchd.user.agents.onepassword-ssh-auth-sock = {
        serviceConfig = {
          Label = "com.1password.SSH_AUTH_SOCK";
          ProgramArguments = [
            "/bin/sh"
            "-c"
            "/bin/ln -sf /Users/${config.my.primaryUser}/Library/Group\\ Containers/2BUA8C4S2C.com.1password/t/agent.sock $SSH_AUTH_SOCK"
          ];
          RunAtLoad = true;
        };
      };
    };
}
