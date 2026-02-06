# Personal MacBook
{ self, inputs }:
{
  username = "stamp";
  hostname = "Lius-MacBook-Pro";

  homeConfiguration = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "aarch64-darwin";
      config.allowUnfree = true;
    };
    extraSpecialArgs = { inherit self inputs; };
    modules = [
      self.homeProfiles.personal
    ];
  };
}
