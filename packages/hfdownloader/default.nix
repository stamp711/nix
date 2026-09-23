# https://github.com/bodaay/HuggingFaceModelDownloader
{
  perSystem =
    { lib, pkgs, ... }:
    {
      packages.hfdownloader = pkgs.buildGoModule (finalAttrs: {
        pname = "hfdownloader";
        version = "3.2.0";

        src = pkgs.fetchFromGitHub {
          owner = "bodaay";
          repo = "HuggingFaceModelDownloader";
          tag = "v${finalAttrs.version}";
          hash = "sha256-XSyAOfh4BrVxcaqB7+1E9gRkTBM6CHNsG2V2BtITv4g=";
        };
        vendorHash = "sha256-DUALCwhuwQZ94uOVjw5wyY8z3fYr9WyDwVc89U34ytM=";

        nativeBuildInputs = [ pkgs.installShellFiles ];

        subPackages = [ "cmd/hfdownloader" ];
        ldflags = [
          "-s"
          "-w"
          "-X main.Version=${finalAttrs.version}"
        ];

        postInstall = lib.optionalString (pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform) ''
          installShellCompletion --cmd hfdownloader \
            --bash <($out/bin/hfdownloader completion bash) \
            --zsh <($out/bin/hfdownloader completion zsh) \
            --fish <($out/bin/hfdownloader completion fish)
        '';

        meta = {
          description = "Hugging Face model downloader with GGUF-aware selection, web UI and mirror sync";
          homepage = "https://github.com/bodaay/HuggingFaceModelDownloader";
          license = lib.licenses.asl20;
          mainProgram = "hfdownloader";
        };
      });
    };
}
