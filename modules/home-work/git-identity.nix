{ inputs, ... }:
let
  private = inputs.private;
in
{
  programs.git = {
    settings = {
      user.name = private.work.git.name;
      user.email = private.work.git.email;
    };

    signing = {
      key = "";
      signByDefault = false;
    };

    ignores = [ ];
  };

  # Work-specific session path
  home.sessionPath = [ ];
}
