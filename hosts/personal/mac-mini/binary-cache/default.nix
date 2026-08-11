let
  cache = {
    host = "lius-mac-mini.boar-char.ts.net";
    keyName = "mac-mini";
    secretKeyFile = ./key.age;
  };
in
{
  # Every personal machine sees this entry.
  flake.nixosModules.personal.my.nix.binary-cache.mac-mini = cache;
  flake.darwinModules.personal.my.nix.binary-cache.mac-mini = cache;

  flake.darwinModules.mac-mini.my.nix.binary-cache.mac-mini.serve = true;
}
