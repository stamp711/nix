# The daemon tries to self-update at runtime.
{
  perSystem =
    { lib, pkgs, ... }:
    {
      packages.raft-computer =
        let
          version = "1.0.18";
          targets = {
            x86_64-linux = {
              file = "raft-computer-linux-x64";
              sha256 = "b39c11ea3a8563b2adbd4c665ff4fbff9b9cfd2689cc37430dcbf246f0f0d34b";
            };
            aarch64-linux = {
              file = "raft-computer-linux-arm64";
              sha256 = "fffa6f06a14308509671707d4a79a6818932f29a3af713858381e4e25e57a95d";
            };
            aarch64-darwin = {
              file = "raft-computer-darwin-arm64";
              sha256 = "b9d2637306a639003ac99cd0a9dc96ec70bc5173d6bdba7b9e5bb3242f690b90";
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
