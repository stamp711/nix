{ inputs, config, ... }:
let
  private = inputs.private;
in
{
  # Identity
  programs.git.settings = {
    user.name = private.personal.git.name;
    user.email = private.personal.git.email;
  };

  # Signing
  programs.git.signing = {
    key = private.personal.git.signingKey;
    signByDefault = true;
  };

  home.file."${config.xdg.configHome}/git/allowed_signers".text = ''
    ${private.personal.git.email} namespaces="git" ${private.personal.git.signingKey}
  '';
}
