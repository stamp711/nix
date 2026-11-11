{ self, ... }:
{
  flake.profiles.homeManager.work = {
    imports = [
      self.homeModules.work-codex
      self.homeModules.github-ratelimit-token
      self.homeModules.personal-wakatime
    ];
  };
}
