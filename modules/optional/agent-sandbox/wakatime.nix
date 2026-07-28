{ self, ... }:
{
  flake.homeModules.agent-sandbox.imports = [ self.homeModules.personal-wakatime ];
}
