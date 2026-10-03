{ inputs, ... }:
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      disabledModules = [ "programs/t3code.nix" ];
      imports = [ "${inputs.hm-t3code-pr}/modules/programs/t3code.nix" ];

      programs.t3code = {
        enable = true;
        # This input splits the CLI and desktop app into separate outputs.
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.t3code.override {
          providerPackages = [ ];
        };
      };
    };
}
