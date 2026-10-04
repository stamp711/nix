# Operator SSH keys.
{ lib, ... }:
let
  nucTpmPubkeyFile = ../../hosts/personal/nuc/ssh-tpm-agent/key.pub;
in
{
  flake.lib.sshPubKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG0Zuk/bYRvsX5WypXgY7aopBeoTNjma1rr6Txtp87JS ssh-apricity"
  ]
  ++ lib.optional (builtins.pathExists nucTpmPubkeyFile) (lib.fileContents nucTpmPubkeyFile);
}
