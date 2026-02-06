{ self, inputs, ... }:
{
  imports = builtins.concatLists (
    map builtins.attrValues [
      self.homeModules
      self.homePersonalModules
    ]
  );
  # Username on all of my machines
  home.username = inputs.private.personal.username;
}
