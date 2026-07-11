# Give the per-user `systemd --user` manager the same PATH a login shell would
# build. Needed because lingered user services start at boot before any login
# happens, so /etc/profile is never sourced and the manager comes up with a
# near-empty PATH. systemd reads any executable under
# /etc/systemd/user-environment-generators/ at startup and adds its KEY=VALUE
# output to the manager environment; we source NixOS's own profile-building
# script there to stay in sync with whatever environment.profiles contains.
#
# Ref:
#   man:systemd.environment-generator(7)
#   https://discourse.nixos.org/t/systemd-user-units-and-no-such-path/8399/5
#
# Result matches GNOME-on-Wayland imported path shown in `systemctl --user show-environment`.
{
  flake.nixosModules.core =
    { config, pkgs, ... }:
    {
      environment.etc."systemd/user-environment-generators/90-path.sh".source =
        pkgs.writeShellScript "generate-user-path" ''
          source ${config.system.build.setEnvironment}
          printf "PATH=%q\n" "$PATH"
        '';
    };
}
