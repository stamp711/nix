# Multica CLI + agent daemon.
{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.multica = pkgs.buildGoModule {
        pname = "multica";
        version = inputs.multica.shortRev or "unstable";
        src = inputs.multica;
        modRoot = "server";
        vendorHash = "sha256-SL//NLuzLV+faAjD7SR9f9j0AaDHel2haZajLJpsj5s=";

        subPackages = [
          "cmd/multica"
          "cmd/server"
          "cmd/migrate"
        ];

        # Upstream builds static; its Dockerfile and .goreleaser.yml both set this.
        env.CGO_ENABLED = 0;
        ldflags = [
          "-s"
          "-w"
        ];

        meta = {
          description = "Managed agents platform: CLI and local agent daemon";
          homepage = "https://multica.ai";
          # Apache 2.0 plus conditions barring hosted/embedded commercial use.
          license = pkgs.lib.licenses.unfree;
          mainProgram = "multica";
        };
      };
    };
}
