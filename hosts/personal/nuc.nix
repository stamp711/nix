{ self, ... }:
let
  username = "stamp";
  hostname = "NUC13RNGi9";
  system = "x86_64-linux";
in
{
  description = "Personal devbox";
  inherit username hostname system;

  homeConfiguration = self.lib.mkHome {
    inherit system username;
    modules = [
      self.homeProfiles.personal
      {
        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIO0ec9IGOqtQ32SRf5RSKjNkB9F8WpyVTnbV1nf2C22";
      }
    ];
  };

  deploy = {
    hostname = "NUC13RNGi9.home";
    remoteBuild = true;
  };
}
