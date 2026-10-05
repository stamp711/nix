{ inputs, ... }:
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      disabledModules = [ "programs/t3code.nix" ];
      imports = [ "${inputs.hm-t3code-pr}/modules/programs/t3code.nix" ];

      programs.t3code = {
        enable = true;
        # Nightly build with the V2 orchestrator, vendored in
        # packages/t3code-nightly (via pkgs.my so standalone home configs work);
        # once a stable release ships V2, switch back to inputs.llm-agents'
        # t3code with providerPackages = [ ].
        package = pkgs.my.t3code-nightly;
      };
    };
}
