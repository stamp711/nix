{
  flake.nixosModules.core = { config, ... }: {
    users.users.${config.my.primaryUser} = {
      uid = 1000;
      isNormalUser = true;
      linger = true;
      extraGroups = [
        "wheel"
        "networkmanager"

        "video"
        "render"
        "input"
        "uinput"
        "dialout"
        "kvm"
        "tss" # TPM access
      ];
    };
  };

  flake.darwinModules.core = { config, ... }: {
    system.primaryUser = config.my.primaryUser;
    # Modules interpolate this but it defaults to null.
    # Activation aborts loudly if the account's real one differs.
    users.users.${config.my.primaryUser}.home = "/Users/${config.my.primaryUser}";
  };

  flake.homeModules.core = { config, ... }: {
    home.username = config.my.primaryUser;
  };
}
