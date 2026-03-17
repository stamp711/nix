{
  flake.nixosModules.cli-environment = {
    security.pam.sshAgentAuth.enable = true;
    security.pam.services.sudo.sshAgentAuth = true;
  };

  flake.darwinModules.cli-environment =
    { lib, pkgs, ... }:
    {
      security.pam.services.sudo_local.touchIdAuth = true;
      security.pam.services.sudo_local.watchIdAuth = true;
      security.pam.services.sudo_local.reattach = true;
      security.pam.services.sudo_local.text = lib.mkAfter ''
        auth sufficient ${pkgs.pam_u2f}/lib/security/pam_u2f.so cue
      '';
    };
}
