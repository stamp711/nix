# The daemon tries to self-update at runtime.
{
  perSystem =
    { lib, pkgs, ... }:
    {
      packages.raft-computer =
        let
          version = "1.0.13";
          targets = {
            x86_64-linux = {
              file = "raft-computer-linux-x64";
              sha256 = "18c656733371fe8e2890f1d6718499f00d79937ab5e4fa1b5ef04e566ab7cf4a";
            };
            aarch64-linux = {
              file = "raft-computer-linux-arm64";
              sha256 = "165429cfc3bd7befd7ad25972e00c0080c5a54636b347221d89e3895711379d7";
            };
            aarch64-darwin = {
              file = "raft-computer-darwin-arm64";
              sha256 = "2b0d725773bef0c0c50a5919d4a8ee00b7d1e1782c7eff6bc4f49d16dad1aa2f";
            };
          };
          target =
            targets.${pkgs.stdenv.hostPlatform.system}
              or (throw "raft-computer: unsupported system ${pkgs.stdenv.hostPlatform.system}");
        in
        pkgs.stdenv.mkDerivation {
          pname = "raft-computer";
          inherit version;
          src = pkgs.fetchurl {
            url = "https://cdn.raft.build/computer/${version}/${target.file}";
            inherit (target) sha256;
          };
          dontUnpack = true;
          dontStrip = true; # would corrupt the SEA blob / break the signed macOS binary
          nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.autoPatchelfHook ];
          buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            pkgs.stdenv.cc.cc.lib
            pkgs.zlib
          ]; # Node SEA: glibc + libstdc++
          installPhase = "install -Dm755 $src $out/bin/raft-computer";
        };
    };
}
