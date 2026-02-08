# Work Git Identity
{ inputs, ... }:
let
  inherit (inputs) private;
in
{
  programs.git.settings = {
    user.name = private.work.git.name;
    user.email = private.work.git.email;
  };

  programs.git.signing.key = private.work.git.signingKey;
}
