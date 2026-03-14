let
  children = [
    (import ./agenix-template.nix)
    (import ./boot-disk.nix)
    (import ./maintenance.nix)
    (import ./secrets.nix)
    (import ./snell.nix)
    (import ./xray-proxy)
  ];
  collectClass = class: builtins.filter (x: x != null) (map (c: c.${class} or null) children);
in
{
  nixos = {
    imports = collectClass "nixos";
  };
  homeManager = {
    imports = collectClass "homeManager";
  };
}
