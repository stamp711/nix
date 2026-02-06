{ self, inputs, ... }:
{
  imports =
    builtins.attrValues self.homeModules
    ++ (with self.homeWorkModules; [
      git-identity
      devbox-proxy
    ]);
  home.username = inputs.private.work.username.devbox;
}
