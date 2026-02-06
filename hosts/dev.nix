# Personal devbox
{ self, inputs }:
{
  username = "stamp";
  hostname = "NUC13RNGi9";

  homeConfiguration = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    extraSpecialArgs = { inherit self inputs; };
    modules = [
      self.homeProfiles.personal
    ];
  };
}
