{ lib, ... }:
{

  flake.darwinModules.desktop-darwin = {
    homebrew.casks = [
      "1password"
      "1password-cli"
    ];
  };

  flake.homeModules.desktop-darwin =
    { config, ... }:
    {
      my.ssh-agent-mux.sockets = [
        "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      ];
    };

  flake.nixosModules.desktop-linux =
    { config, ... }:
    {
      programs._1password.enable = true;
      programs._1password-gui = {
        enable = true;
        polkitPolicyOwners = builtins.attrNames (lib.filterAttrs (_: u: u.isNormalUser) config.users.users);
      };
    };

  flake.homeModules.desktop-linux =
    { config, ... }:
    {
      my.ssh-agent-mux.sockets = [ "${config.home.homeDirectory}/.1password/agent.sock" ];

      wayland.windowManager.niri.settings._children = [
        {
          window-rule = {
            match._props.app-id = "^com[.]onepassword[.]OnePassword$";
            open-floating = true;
          };
        }
      ];
    };

}
