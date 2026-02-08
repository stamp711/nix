{
  description = "Personal Git identity and signing key";

  module =
    { inputs, ... }:
    let
      inherit (inputs) private;
    in
    {
      programs.git.settings = {
        user.name = private.personal.git.name;
        user.email = private.personal.git.email;
      };

      programs.git.signing.key = private.personal.git.signingKey;
    };
}
