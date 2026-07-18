# Operator SSH key, authorized on personal hosts.
{ lib, self, ... }: {

  flake.nixosModules.personal = {
    # Hack: Extend the users.users submodule to add SSH keys for all normal users.
    # Uses submodule merging to avoid infinite recursion with config.users.users.
    options.users.users = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { config, ... }:
          {
            config.openssh.authorizedKeys.keys = lib.mkIf config.isNormalUser [ self.lib.sshPubKey ];
          }
        )
      );
    };
  };

  flake.darwinModules.personal = { config, ... }: {
    users.users.${config.my.primaryUser}.openssh.authorizedKeys.keys = [ self.lib.sshPubKey ];
  };

}
