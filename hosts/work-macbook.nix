# Work MacBook
{ self, inputs }:
let
  host = inputs.private.work.hosts.macbook;
  username = host.username;
  hostname = host.hostname;
  system = "aarch64-darwin";
in
{
  inherit username hostname system;

  homeConfiguration = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    extraSpecialArgs = { inherit self inputs; };
    modules = [
      { home.username = username; }
      self.homeProfiles.work-laptop
    ];
  };
}
