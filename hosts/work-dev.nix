# Work devbox
{ self, inputs }:
{
  username = "REDACTED";
  hostname = "work-dev";

  homeConfiguration = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    extraSpecialArgs = { inherit self inputs; };
    modules = [
      self.homeProfiles.work-devbox
    ];
  };
}
