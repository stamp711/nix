{
  flake.nixosModules.core = {
    # Decrypt using the persistent host key (matches services.openssh.hostKeys
    # path in modules/shared/core/ssh.nix).
    age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  };

  flake.homeModules.core =
    { config, ... }:
    {
      # Default secretsDir is a shell expression, override with a literal path instead.
      # It's only a symlink, the actual secrets are still in an ephemeral runtime dir.
      age.secretsDir = "${config.xdg.dataHome}/agenix";
    };
}
