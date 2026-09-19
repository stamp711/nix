let
  kernelSource = import ./source.nix;
  inherit (kernelSource) architectures;
in
{
  perSystem =
    {
      config,
      lib,
      pkgs,
      system,
      ...
    }:
    {
      packages =
        lib.optionalAttrs (architectures ? ${system}) {
          linux_nvidia = pkgs.callPackage ./package.nix { inherit kernelSource; };
        }
        // lib.optionalAttrs (system == "x86_64-linux") {
          # Runs on x86_64 Linux and produces a kernel for ARM64 Linux.
          linux_nvidia_aarch64 = pkgs.pkgsCross.aarch64-multiplatform.callPackage ./package.nix {
            inherit kernelSource;
          };
        };

      # Configuration tests run natively, including on Darwin; they build no kernel.
      checks = {
        linux-nvidia-config-checker = import ./config/patch-generate-config/tests { inherit pkgs; };
        linux-nvidia-config = import ./config/test.nix { inherit pkgs; };
        linux-nvidia-adaptations = import ./config/adaptations/test.nix { inherit pkgs kernelSource; };
        linux-nvidia-read-annotations = import ./config/read-annotations/tests {
          inherit pkgs kernelSource;
        };
      }
      // lib.optionalAttrs (architectures ? ${system}) {
        # Builds only the .config with the target toolchain, not the kernel.
        linux-nvidia-config-build = config.packages.linux_nvidia.configfile;
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        linux-nvidia-aarch64-config-build = config.packages.linux_nvidia_aarch64.configfile;
      };
    };
}
