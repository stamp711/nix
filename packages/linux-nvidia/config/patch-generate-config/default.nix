# Patch nixpkgs' generate-config.pl validation:
# - Accept missing options requested as n; Kconfig may omit disabled options.
# - Check mismatches even when the actual value is 0 or an empty string.
# Input: upstream script path. Output: patched script in the Nix store.
# Fail if the expected upstream code changes, so this patch gets reviewed.
{ lib, writeText }:
file:
let
  original = builtins.readFile file;
  replacements = [
    {
      from = "unless defined $config{$name};";
      to = ''unless defined $config{$name} || $answers{$name} eq "n";'';
    }
    {
      # Perl's truthiness otherwise skips mismatches whose actual value is 0 or "".
      from = "if $config{$name} && $config{$name} ne $answers{$name};";
      to = "if defined $config{$name} && $config{$name} ne $answers{$name};";
    }
  ];
in
assert lib.all (
  replacement:
  lib.assertMsg (
    builtins.length (lib.splitString replacement.from original) == 2
  ) "linux-nvidia: nixpkgs generate-config.pl changed; review config/patch-generate-config"
) replacements;
writeText "generate-config.pl" (
  builtins.replaceStrings (map (r: r.from) replacements) (map (r: r.to) replacements) original
)
