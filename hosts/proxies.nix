{
  self,
  inputs,
  lib,
  ...
}:
let
  system = "x86_64-linux";

  mkProxy = hostname: hostPubkey: {
    flake.nixosConfigurations.${hostname} = self.lib.mkNixos {
      inherit system;
      modules = [
        self.profiles.nixos.kvm-proxy
        {
          networking.hostName = hostname;
          age.rekey.hostPubkey = hostPubkey;
          users.users.stamp = {
            uid = 1000;
            isNormalUser = true;
            extraGroups = [ "wheel" ];
          };
        }
      ];
    };
    flake.deploy.nodes.${hostname} = {
      hostname = "proxy-${lib.toLower hostname}";
      remoteBuild = false;
      profiles.system = {
        user = "root";
        path = inputs.deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.${hostname};
      };
    };
  };
in
lib.mkMerge [
  (mkProxy "ATT" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKWTLSyOkQ48zjJfXLWrvUkEhf7uyq8O2wcU2bcoyG2T")
  (mkProxy "NURO" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB50dHwZLQyKtq7VV9pa9F4QJJtGW0jgJ+RsV/x2IpJI")
  (mkProxy "VIA" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG21GuCJYYrjfsyvKO2LeQVTS4zYkPDEXf4JVpWoujdY")
]
