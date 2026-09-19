# Explicit differences from NVIDIA's policy. Keep upstream-value expectations
# beside overrides so a source update requires review when their premise changes.
{
  # These symbols have no Kconfig prompt: values come from the build environment
  # or other symbols, so NVIDIA's recorded values are not configuration inputs.
  omittedSymbolsByFile = {
    "init/Kconfig" = [
      # Toolchain identity, versions and availability.
      "CC_VERSION_TEXT"
      "CC_IS_GCC"
      "CC_IS_CLANG"
      "GCC_VERSION"
      "CLANG_VERSION"
      "AS_IS_GNU"
      "AS_IS_LLVM"
      "AS_VERSION"
      "LD_IS_BFD"
      "LD_IS_LLD"
      "LD_VERSION"
      "LLD_VERSION"
      "RUST_IS_AVAILABLE"
      "RUSTC_VERSION"
      "RUSTC_LLVM_VERSION"
      "RUSTC_VERSION_TEXT"
      "BINDGEN_VERSION_TEXT"
      "PAHOLE_VERSION"
      # Compiler/linker capabilities recomputed for our toolchain.
      "CC_CAN_LINK"
      "GCC_ASM_GOTO_OUTPUT_BROKEN"
      "CC_HAS_ASM_GOTO_OUTPUT"
      "CC_HAS_ASM_GOTO_TIED_OUTPUT"
      "TOOLS_SUPPORT_RELR"
      "CC_HAS_ASM_INLINE"
      "CC_HAS_ASSUME"
      "CC_HAS_NO_PROFILE_FN_ATTR"
      "CC_HAS_COUNTED_BY"
      "CC_HAS_COUNTED_BY_PTR"
      "CC_HAS_BROKEN_COUNTED_BY_REF"
      "CC_HAS_MULTIDIMENSIONAL_NONSTRING"
      "LD_CAN_USE_KEEP_IN_OVERLAY"
      "RUSTC_HAS_SLICE_AS_FLATTENED"
      "RUSTC_HAS_COERCE_POINTEE"
      "RUSTC_HAS_SPAN_FILE"
      "RUSTC_HAS_UNNECESSARY_TRANSMUTES"
      "RUSTC_HAS_FILE_WITH_NUL"
      "RUSTC_HAS_FILE_AS_C_STR"
    ];
    # Selected by BLK_DEV_DM; preserve NVIDIA's BLK_DEV_DM=y itself.
    "drivers/md/Kconfig" = [ "BLK_DEV_DM_BUILTIN" ];
  };

  overrides = {
    # Standalone userspace examples, not kernel drivers. Building these would
    # require libc startup objects and runtime libraries in the kernel toolchain.
    SAMPLE_AUXDISPLAY = {
      expectedUpstream = "y";
      value = "n";
    };
    SAMPLE_WATCHDOG = {
      expectedUpstream = "y";
      value = "n";
    };
    # Do not embed Ubuntu's certificate bundles in the Nix-built kernel.
    SYSTEM_TRUSTED_KEYS = {
      expectedUpstream = "\"debian/canonical-certs.pem\"";
      value = "\"\"";
    };
    SYSTEM_REVOCATION_KEYS = {
      expectedUpstream = "\"debian/canonical-revoked-certs.pem\"";
      value = "\"\"";
    };
  };
}
