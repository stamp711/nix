# Parsing and policy selection use inline text, without reading fixture files.
{ lib }:
let
  parser = import ../parse.nix { inherit lib; };
  document = parser.parseText ''
    # FORMAT: 4
    # ARCH: amd64 arm64
    # FLAVOUR: arm64-nvidia arm64-nvidia-64k
    # FLAVOUR_DEP: {'arm64-nvidia': 'arm64-generic', 'arm64-nvidia-64k': 'arm64-generic-64k'}

    CONFIG_INHERITED policy<{'amd64': 'n', 'arm64': 'y'}>
    CONFIG_FLAVOUR policy<{'arm64': 'n', 'arm64-generic': 'm', 'arm64-generic-64k': 'y'}>
    CONFIG_ARCH_OVERRIDE policy<{'arm64': 'n', 'arm64-generic': 'y', 'arm64-nvidia': 'y'}>
    CONFIG_UNDEFINED policy<{'arm64': 'y'}>
    CONFIG_OTHER_ARCH policy<{'amd64': 'y'}>
    CONFIG_BLK_DEV_DM policy<{'arm64': 'y'}>
    CONFIG_GCC_VERSION policy<{'arm64': '130300'}>
    CONFIG_SYSTEM_TRUSTED_KEYS policy<{'arm64': '"debian/canonical-certs.pem"'}>
    CONFIG_ARCH_OVERRIDE policy<{'arm64': 'm'}>
    CONFIG_FLAVOUR_OVERRIDE policy<{'arm64': 'n', 'arm64-nvidia': 'y'}>
    CONFIG_POLICY_ORDER policy<{'arm64-nvidia': 'y', 'arm64': 'n'}>
    CONFIG_UNDEFINED policy<{'arm64': '-'}>
    CONFIG_DISABLED policy<{'arm64': 'n'}>
    CONFIG_NUMBER policy<{'arm64': '128'}>
    CONFIG_HEX policy<{'arm64': '0x1000'}>
    CONFIG_STRING policy<{'arm64': '"hello world"'}>
    CONFIG_EMPTY policy<{'arm64': '""'}>
    CONFIG_QUOTES policy<{'arm64': '"it\'s \\"quoted\\""'}>
    CONFIG_DOLLAR policy<{'arm64': '"''${literal}"'}>
    CONFIG_DOUBLE_QUOTED policy<{"arm64": "\"quoted\""}>
    CONFIG_DISABLED note<'Notes do not change policy'>
    CONFIG_BACKSLASHES policy<{'arm64': '"path\\\\name\\\\\\"quoted\\""'}>
    CONFIG_SAMPLE_AUXDISPLAY policy<{'arm64': 'y'}>
    CONFIG_SAMPLE_WATCHDOG policy<{'arm64': 'y'}>
    CONFIG_SYSTEM_REVOCATION_KEYS policy<{'arm64': '"debian/canonical-revoked-certs.pem"'}>
    CONFIG_LATE_OVERRIDE policy<{'arm64': 'n'}>
    CONFIG_LATE_OVERRIDE policy<{'arm64-nvidia': 'y'}>
  '';
  select =
    {
      arch ? "arm64",
      flavour ? "nvidia",
      headers ? document.headers,
    }:
    parser.selectConfig {
      inherit arch flavour headers;
      policies = document.entries;
    };
  config = select { };
  config64k = select { flavour = "nvidia-64k"; };
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
  includes =
    (parser.parseText ''
      include "./vendor"
      CONFIG_OVERRIDE policy<{'arm64': 'y'}>
      include "../base"
    '').entries;
in
assert config == expected;
assert config64k.CONFIG_FLAVOUR == "y";
assert config64k.CONFIG_FLAVOUR_OVERRIDE == "n";
# Include directives remain in order for the loader, without opening any files.
assert
  map (entry: entry.include or entry.name) includes == [
    "./vendor"
    "CONFIG_OVERRIDE"
    "../base"
  ];
assert fails (select {
  flavour = "arm64-nvidia";
});
assert fails (select {
  arch = "riscv64";
});
assert fails (select {
  headers = lib.overrideExisting document.headers { format = "3"; };
});
assert fails (parser.parseText "CONFIG_MISSPELLED polcy<{'arm64': 'y'}>");
true
