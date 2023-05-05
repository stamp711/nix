{...}: rec {
  base = {imports = [core];};

  core = {
    pkgs,
    lib,
    ...
  }: {
    system.stateVersion = 4;
    programs.zsh.enable = true;
  };

  setUserHome = user: {...}: {users.users.${user}.home = "/Users/" + user;};
}
