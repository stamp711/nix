# Shared recipe for native and cross builds; annotations follow the target system.
{
  lib,
  stdenv,
  buildLinux,
  writeText,
  kernelSource,
  ...
}@args:
let
  patchGenerateConfig = import ./config/patch-generate-config { inherit lib writeText; };
  # A buildLinux variant that replaces linux-config's generateConfig script
  # with our patched version for applying and validating kernel settings.
  buildLinuxWithChecker = buildLinux.override {
    stdenv = lib.overrideExisting stdenv {
      mkDerivation =
        args:
        stdenv.mkDerivation (
          if builtins.isAttrs args && args.pname or null == "linux-config" then
            assert lib.assertMsg (
              args ? generateConfig
            ) "linux-nvidia: buildLinux config derivation changed; review checker wiring";
            lib.overrideExisting args { generateConfig = patchGenerateConfig args.generateConfig; }
          else
            args
        );
    };
  };
  nvidiaConfig = import ./config {
    inherit lib;
    inherit (kernelSource) src annotationsPath;
    arch = kernelSource.architectures.${stdenv.hostPlatform.system};
  };
  seedFile = writeText "linux-nvidia.config" nvidiaConfig.seedConfig;
in
buildLinuxWithChecker (
  # Forward kernel build arguments; keep recipe dependencies out of the derivation.
  lib.attrsets.unionOfDisjoint
    (builtins.removeAttrs args [
      "lib"
      "stdenv"
      "buildLinux"
      "writeText"
      "kernelSource"
    ])
    {
      pname = "linux-nvidia";
      inherit (kernelSource) src;
      version = "${kernelSource.version}-nvidia";
      modDirVersion = kernelSource.version;
      # NVIDIA supplies the complete policy; nixpkgs' defaults can require options
      # beneath features that this policy disables.
      enableCommonConfig = false;
      # Load the complete adapted policy before interactive configuration, so an
      # earlier prompt can depend on a later setting (e.g. BLK_DEV_DM=y needs DAX=y).
      defconfig = "alldefconfig";
      extraMakeFlags = [ "KCONFIG_ALLCONFIG=${seedFile}" ];
      # Missing or incorrectly resolved required settings must fail the config build.
      ignoreConfigErrors = false;
      # Reuse the same policy for nixpkgs' config answers and final requested-value
      # checks: seeding alone does not detect settings that Kconfig changes or drops.
      structuredExtraConfig = nvidiaConfig.structuredConfig;

      extraMeta.platforms = builtins.attrNames kernelSource.architectures;
    }
)
