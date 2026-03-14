let
  children = [
    (import ./agenix-rekey.nix)
    (import ./base.nix)
  ];
  collectClass = class: builtins.filter (x: x != null) (map (c: c.${class} or null) children);
in
{
  nixos.imports = collectClass "nixos";
  darwin.imports = collectClass "darwin";
  homeManager.imports = collectClass "homeManager";
}
