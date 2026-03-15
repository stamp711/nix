let
  sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG0Zuk/bYRvsX5WypXgY7aopBeoTNjma1rr6Txtp87JS ssh-apricity";
in
{
  flake.homeModules.core = { };

  flake.nixosModules.core =
    { lib, ... }:
    {
      # Hack: Extend the users.users submodule to add SSH keys for all normal users.
      # Uses submodule merging to avoid infinite recursion with config.users.users.
      options.users.users = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            { config, ... }:
            {
              config.openssh.authorizedKeys.keys = lib.mkIf config.isNormalUser [ sshPubKey ];
            }
          )
        );
      };

      config = {
        # SSH server
        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            PermitRootLogin = "no";
          };
        };

        # ET server - enable but no firewall setting, so not exposed on proxy servers
        services.eternal-terminal.enable = true;
      };
    };

  flake.darwinModules.core =
    { config, ... }:
    {
      users.users.${config.my.primaryUser}.openssh.authorizedKeys.keys = [ sshPubKey ];
      services.eternal-terminal.enable = true;
    };
}
