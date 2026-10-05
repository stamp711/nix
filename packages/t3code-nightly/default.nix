# T3 Code nightly with the V2 orchestrator. Retargets llm-agents' t3code
# expression to the nightly channel by patching its pinned source at eval
# time, so upstream keeps the build logic authoritative. Remove this package
# and point modules/in-profile/.../llm/t3code.nix back at inputs.llm-agents
# once the V2 orchestrator reaches a stable release.
{ inputs, ... }:
{
  perSystem =
    { lib, pkgs, ... }:
    let
      llmPackages = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

      # llm-agents builds inside its own callPackage scope; these helpers live
      # there rather than in nixpkgs, so pass them explicitly.
      scopeArgs = {
        flake = inputs.llm-agents;
        inherit (llmPackages) formatelf versionCheckHomeHook;
      };

      # The three anchors are the only expected drift between the stable
      # expression and the nightly: the version plus the src and pnpm hashes.
      # A stale hash fails loudly on the fixed-output mismatch; the asserts
      # catch a rewritten upstream expression at eval time instead.
      nightlyVersion = "0.0.46-nightly.20261005.2676";
      nightlySrcHash = "sha256-cy8N9Xsd0qRQWJnLx7pVP/j2wlntEiMon1V0mujohkc=";
      nightlyPnpmHash = "sha256-CByfcfZjPR2GiJjFakUAgm1BsuWKqyGM9GwDJWlYDLs=";

      unwrappedSource =
        let
          upstream = builtins.readFile "${inputs.llm-agents}/packages/t3code/unwrapped.nix";
          patched =
            builtins.replaceStrings
              [
                ''version = "0.0.45";''
                ''hash = "sha256-8drTHjFqa2vJ96jhpRZXmNbtbXtKk1q40jOEp9dohNc=";''
                ''hash = "sha256-2dGEHOQrnidTei54NlZTJh5u5/i810hb2LddK4XfUNQ=";''
              ]
              [
                ''version = "${nightlyVersion}";''
                ''hash = "${nightlySrcHash}";''
                ''hash = "${nightlyPnpmHash}";''
              ]
              upstream;
        in
        assert !lib.hasInfix ''version = "0.0.45";'' patched;
        assert !lib.hasInfix "sha256-8drTHjFqa2vJ96jhpRZXmNbtbXtKk1q40jOEp9dohNc=" patched;
        assert !lib.hasInfix "sha256-2dGEHOQrnidTei54NlZTJh5u5/i810hb2LddK4XfUNQ=" patched;
        builtins.toFile "t3code-unwrapped.nix" patched;
    in
    {
      packages.t3code-nightly = llmPackages.t3code.override {
        t3code-unwrapped = pkgs.callPackage unwrappedSource scopeArgs;
        # Providers are already installed and managed elsewhere on our hosts.
        providerPackages = [ ];
      };
    };
}
