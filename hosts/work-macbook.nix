# Work MacBook
{ self, inputs }:
{
  username = "REDACTED";
  hostname = "work-mbp";

  homeConfiguration = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "aarch64-darwin";
      config.allowUnfree = true;
    };
    extraSpecialArgs = { inherit self inputs; };
    modules = [
      self.homeProfiles.work
    ];
  };
}
