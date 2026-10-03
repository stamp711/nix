{ inputs, ... }:
{
  flake.homeModules.cli-programs =
    { config, ... }:
    {
      programs.nix-search-tv.enable = true;
      programs.nix-search-tv.settings = {
        indexes = [
          "nixpkgs"
          "home-manager"
          "nixos"
          "darwin"
          "nur"
        ];

        # Third-party module options not covered by the builtin indexes.
        # Complex ones are in a separate dir.
        experimental.options_file = {

          agenix = config.lib.my.mkOpts inputs.agenix.nixosModules.default;
          hermes-agent = config.lib.my.mkOpts inputs.hermes-agent.nixosModules.default;
          hermes-webui = config.lib.my.mkOpts inputs.hermes-webui.nixosModules.default;
          impermanence = config.lib.my.mkOpts inputs.impermanence.nixosModules.impermanence;
          microvm = config.lib.my.mkOpts inputs.microvm.nixosModules.microvm;
          nix-homebrew = config.lib.my.mkOpts inputs.nix-homebrew.darwinModules.nix-homebrew;
          nixos-wsl = config.lib.my.mkOpts inputs.nixos-wsl.nixosModules.default;
          nixvirt = config.lib.my.mkOpts inputs.NixVirt.nixosModules.default;

        };
      };
    };
}
