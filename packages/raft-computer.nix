# The daemon tries to self-update at runtime.
{
  perSystem =
    { lib, pkgs, ... }:
    {
      packages.raft-computer =
        let
          version = "1.0.16";
          targets = {
            x86_64-linux = {
              file = "raft-computer-linux-x64";
              sha256 = "d46c2f1a76bded81faf1b887ed26604ac0094b75eed10c634027e562bbfbd4f7";
            };
            aarch64-linux = {
              file = "raft-computer-linux-arm64";
              sha256 = "93ec23e1200afee8a83bf9c49ca90f16101380ea641f815637859845412a2f05";
            };
            aarch64-darwin = {
              file = "raft-computer-darwin-arm64";
              sha256 = "a61df7259c497864f5ae584131ea48ee58dd873358365b4297e2d8bbd12d6b42";
            };
          };
          target =
            targets.${pkgs.stdenv.hostPlatform.system}
              or (throw "raft-computer: unsupported system ${pkgs.stdenv.hostPlatform.system}");

          # New in 1.0.15, the daemon loads it from beside its own executable.
          photonWasm = pkgs.fetchurl {
            url = "https://cdn.raft.build/computer/${version}/photon_rs_bg.wasm";
            sha256 = "10468181565c56004c867f3a4af96f89a0ef5a63a72f2b5fb12c1f1992a3615c";
          };
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
          installPhase = ''
            install -Dm755 $src $out/bin/raft-computer
            install -Dm444 ${photonWasm} $out/bin/photon_rs_bg.wasm
          '';
        };
    };
}
