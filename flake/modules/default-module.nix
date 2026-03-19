# Satisfy the flake.flakeModule → flakeModules.default rename alias
# that upstream nix evaluates eagerly (unlike determinate nix).
{
  flake.flakeModules.default = { };
}
