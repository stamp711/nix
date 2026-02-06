{ self, inputs, ... }:
{
  imports =
    builtins.attrValues self.homeModules
    ++ (with self.homeWorkModules; [
      git-identity
    ]);
  home.username = inputs.private.work.username.laptop;
}
