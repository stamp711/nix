let
  cache = {
    host = "nuc.boar-char.ts.net";
    keyName = "nuc-cache";
    secretKeyFile = ./key.age;
  };
in
{
  # Every personal machine sees this entry.
  flake.nixosModules.personal.my.nix.binary-cache.nuc = cache;
  flake.darwinModules.personal.my.nix.binary-cache.nuc = cache;

  flake.nixosModules.nuc.my.nix.binary-cache.nuc.serve = true;
}
