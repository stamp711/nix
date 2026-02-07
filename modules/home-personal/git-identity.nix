# Personal Git Identity
{ inputs, ... }:
let
  private = inputs.private;
in
{
  programs.git.settings = {
    user.name = private.personal.git.name;
    user.email = private.personal.git.email;
  };

  programs.git.signing.key = private.personal.git.signingKey;
}
