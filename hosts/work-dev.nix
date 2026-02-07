# Work devbox
{ self, inputs }:
let
  host = inputs.private.work.hosts.dev;
  username = host.username;
  hostname = host.hostname;
  system = "x86_64-linux";
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
      self.homeProfiles.work-devbox
    ];
  };

  deploy = {
    hostname = host.address;
    remoteBuild = true;
  };
}
