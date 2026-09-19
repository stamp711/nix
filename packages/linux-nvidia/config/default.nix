# Input: NVIDIA's annotation files from the pinned kernel source and an architecture.
# Output: the same NVIDIA settings in two formats:
# - seedConfig: .config text to initialize Kconfig before it asks questions.
# - structuredConfig: Nix settings for nixpkgs to apply and check in the final .config.
# Converts values, omits computed fields and applies explicit Nix adaptations.
{
  lib,
  src,
  annotationsPath,
  arch,
}:
let
  upstreamConfig = import ./read-annotations { inherit lib; } {
    file = "${toString src}/${annotationsPath}";
    inherit arch;
    flavour = "nvidia";
  };
  adaptations = import ./adaptations;
  omittedSymbols = map (name: "CONFIG_${name}") (
    lib.concatLists (builtins.attrValues adaptations.omittedSymbolsByFile)
  );
  overrideValues = lib.mapAttrs' (name: rule: {
    name = "CONFIG_${name}";
    inherit (rule) value;
  }) adaptations.overrides;
  # Preserve all other NVIDIA settings, including device-mapper, empty paths,
  # release strings and the kernel's default module-signing key location.
  adaptedConfig =
    let
      retainedConfig = builtins.removeAttrs upstreamConfig omittedSymbols;
      missingOverrideTargets = builtins.filter (name: !(builtins.hasAttr name retainedConfig)) (
        builtins.attrNames overrideValues
      );
    in
    assert lib.assertMsg (missingOverrideTargets == [ ])
      "linux-nvidia: adaptation targets missing from NVIDIA config: ${lib.concatStringsSep ", " missingOverrideTargets}";
    lib.overrideExisting retainedConfig overrideValues;
  toKernelValue =
    value:
    if value == "y" then
      lib.kernel.yes
    else if value == "m" then
      lib.kernel.module
    else if value == "n" then
      lib.kernel.no
    else
      # Annotations use .config syntax; nixpkgs expects decoded string contents.
      # Kconfig escapes double quotes and backslashes, not JSON escape sequences.
      lib.kernel.freeform (
        if lib.hasPrefix "\"" value && lib.hasSuffix "\"" value then
          builtins.replaceStrings [ "\\\"" "\\\\" ] [ "\"" "\\" ] (
            lib.removeSuffix "\"" (lib.removePrefix "\"" value)
          )
        else
          value
      );
in
{
  # Keep Kconfig quoting intact; both outputs come from the same adapted settings.
  seedConfig = lib.concatStrings (
    lib.mapAttrsToList (
      name: value: if value == "n" then "# ${name} is not set\n" else "${name}=${value}\n"
    ) adaptedConfig
  );
  structuredConfig = lib.mapAttrs' (name: value: {
    name = lib.removePrefix "CONFIG_" name;
    value = lib.mkForce (toKernelValue value);
  }) adaptedConfig;
}
