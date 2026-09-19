# Tests config/default.nix: conversion to Nix settings and packaging adaptations.
{ pkgs }:
let
  inherit (pkgs) lib;
  nvidiaConfig = import ./. {
    inherit lib;
    src = ./read-annotations/tests/fixtures;
    annotationsPath = "root";
    arch = "arm64";
  };
  settings = nvidiaConfig.structuredConfig;
  seedLines = lib.splitString "\n" nvidiaConfig.seedConfig;
in
# The seed uses Kconfig syntax, including escaped strings and explicit disabling.
assert builtins.elem "CONFIG_BLK_DEV_DM=y" seedLines;
assert builtins.elem "# CONFIG_SAMPLE_AUXDISPLAY is not set" seedLines;
assert builtins.elem "# CONFIG_SAMPLE_WATCHDOG is not set" seedLines;
assert builtins.elem "# CONFIG_DISABLED is not set" seedLines;
assert builtins.elem "CONFIG_FLAVOUR=m" seedLines;
assert builtins.elem ''CONFIG_STRING="hello world"'' seedLines;
assert builtins.elem ''CONFIG_EMPTY=""'' seedLines;
assert builtins.elem ''CONFIG_QUOTES="it's \"quoted\""'' seedLines;
assert builtins.elem ''CONFIG_BACKSLASHES="path\\name\\\"quoted\""'' seedLines;
assert builtins.elem ''CONFIG_SYSTEM_TRUSTED_KEYS=""'' seedLines;
assert builtins.elem ''CONFIG_SYSTEM_REVOCATION_KEYS=""'' seedLines;
assert builtins.elem "CONFIG_NUMBER=128" seedLines;
assert builtins.elem "CONFIG_HEX=0x1000" seedLines;
assert !(lib.hasInfix "CONFIG_GCC_VERSION" nvidiaConfig.seedConfig);
# The structured form decodes strings for nixpkgs' answers and checks.
assert settings.INHERITED == lib.mkForce lib.kernel.yes;
assert settings.DISABLED == lib.mkForce lib.kernel.no;
assert settings.FLAVOUR == lib.mkForce lib.kernel.module;
assert settings.STRING == lib.mkForce (lib.kernel.freeform "hello world");
assert settings.EMPTY == lib.mkForce (lib.kernel.freeform "");
assert settings.QUOTES == lib.mkForce (lib.kernel.freeform ''it's "quoted"'');
assert settings.BACKSLASHES == lib.mkForce (lib.kernel.freeform ''path\name\"quoted"'');
assert settings.DOLLAR == lib.mkForce (lib.kernel.freeform "\${literal}");
assert settings.NUMBER == lib.mkForce (lib.kernel.freeform "128");
assert settings.HEX == lib.mkForce (lib.kernel.freeform "0x1000");
assert !(settings ? GCC_VERSION);
assert settings.BLK_DEV_DM == lib.mkForce lib.kernel.yes;
assert settings.SAMPLE_AUXDISPLAY == lib.mkForce lib.kernel.no;
assert settings.SAMPLE_WATCHDOG == lib.mkForce lib.kernel.no;
assert settings.SYSTEM_TRUSTED_KEYS == lib.mkForce (lib.kernel.freeform "");
assert settings.SYSTEM_REVOCATION_KEYS == lib.mkForce (lib.kernel.freeform "");
pkgs.runCommand "linux-nvidia-config-test" { } ''
  touch "$out"
''
