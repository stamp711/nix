{ self, inputs, ... }:
let
  username = "stamp";
  hostname = "VIA";
  system = "x86_64-linux";
  hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICq8tSt+rdX9EJXMNsmy716vCBABcwL7nGslkPEvUw9b";
in
{
  flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
    inherit system;
    modules = [
      self.profiles.nixos.kvm-proxy
      {
        networking.hostName = hostname;
        age.rekey.hostPubkey = hostPubkey;

        # Primary user
        users.users.${username} = {
          uid = 1000;
          isNormalUser = true;
          extraGroups = [ "wheel" ];
        };
      }
    ];
  };

  flake.deploy.nodes.${hostname} = {
    hostname = "proxy-via";
    remoteBuild = false;
    profiles.system = {
      user = "root";
      path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${hostname};
    };
  };
}
