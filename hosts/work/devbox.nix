{ self, inputs, ... }:
let
  username = "liuxuyang.plt";
  hostname = "n37-098-023";
  system = "x86_64-linux";
in
{
  flake.homeConfigurations."${username}@${hostname}" = self.lib.mkHome {
    inherit system username;
    modules = [
      self.profiles.homeManager.work-devbox
      {
        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGGfAr2tMhcrbtdxi2RjGCaXCTQGWB3dBlTEXN6/DUxE";
      }
    ];
  };

  flake.deploy.nodes.${hostname} = {
    hostname = "dev";
    sshUser = username;
    remoteBuild = true;
    profiles.home-manager = {
      user = username;
      path =
        inputs.deploy-rs.lib.${system}.activate.home-manager
          self.homeConfigurations."${username}@${hostname}";
    };
  };
}
