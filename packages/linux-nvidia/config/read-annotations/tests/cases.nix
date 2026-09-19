# Annotation parsing: includes, inheritance, values and invalid inputs.
{ lib }:
let
  readAnnotations = import ../. { inherit lib; };
  file = ./fixtures/root;
  config = readAnnotations {
    inherit file;
    arch = "arm64";
  };
  config64k = readAnnotations {
    inherit file;
    arch = "arm64";
    flavour = "nvidia-64k";
  };
  fails = value: !(builtins.tryEval (builtins.deepSeq value true)).success;
  expected = {
    CONFIG_INHERITED = "y";
    CONFIG_FLAVOUR = "m";
    CONFIG_ARCH_OVERRIDE = "m";
    CONFIG_FLAVOUR_OVERRIDE = "y";
    CONFIG_POLICY_ORDER = "n";
    CONFIG_DISABLED = "n";
    CONFIG_NUMBER = "128";
    CONFIG_HEX = "0x1000";
    CONFIG_STRING = ''"hello world"'';
    CONFIG_BACKSLASHES = ''"path\\name\\\"quoted\""'';
    CONFIG_EMPTY = ''""'';
    CONFIG_QUOTES = ''"it's \"quoted\""'';
    CONFIG_DOLLAR = ''"''${literal}"'';
    CONFIG_DOUBLE_QUOTED = ''"quoted"'';
    CONFIG_LATE_OVERRIDE = "y";
    CONFIG_BLK_DEV_DM = "y";
    CONFIG_GCC_VERSION = "130300";
    CONFIG_SAMPLE_AUXDISPLAY = "y";
    CONFIG_SAMPLE_WATCHDOG = "y";
    CONFIG_SYSTEM_REVOCATION_KEYS = ''"debian/canonical-revoked-certs.pem"'';
    CONFIG_SYSTEM_TRUSTED_KEYS = ''"debian/canonical-certs.pem"'';
  };
in
assert config == expected;
# Fetchers supply strings with store context, unlike literal local paths.
assert
  readAnnotations {
    file = "${./fixtures}/root";
    arch = "arm64";
  } == expected;
assert config64k.CONFIG_FLAVOUR == "y";
assert config64k.CONFIG_FLAVOUR_OVERRIDE == "n";
assert fails (readAnnotations {
  inherit file;
  arch = "arm64";
  flavour = "arm64-nvidia";
});
assert fails (readAnnotations {
  inherit file;
  arch = "riscv64";
});
assert fails (readAnnotations {
  file = ./fixtures/cycle;
  arch = "arm64";
});
assert fails (readAnnotations {
  file = ./fixtures/invalid;
  arch = "arm64";
});
true
