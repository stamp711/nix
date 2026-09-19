let
  # Release tag resolves to 15ed309b952d98e7c13bdc3cd0e32222308a1cc6.
  tag = "Ubuntu-nvidia-7.0-7.0.0-1020.20_24.04.1";
  version = "7.0.14";
in
{
  inherit tag version;

  # Nix system names mapped to the architecture names used by the annotations.
  architectures = {
    aarch64-linux = "arm64";
    x86_64-linux = "amd64";
  };

  annotationsPath = "debian.nvidia-7.0/config/annotations";

  # The annotations are read during evaluation. Use the evaluator's pinned
  # fetcher so that doing so never builds a Linux fetch derivation on Darwin.
  src = builtins.fetchTree {
    type = "tarball";
    url = "https://github.com/NVIDIA/NV-Kernels/archive/refs/tags/${tag}.tar.gz";
    narHash = "sha256-mfx3nfVfjXB2Og9i6V4flD2RwbsUcmp9YclWd28MysE=";
  };
}
