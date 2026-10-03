{ inputs, lib, ... }:
let
  stylixConfig =
    { pkgs, ... }:
    {
      stylix = {
        enable = true;
        autoEnable = false;
        base16Scheme = inputs.stylix.inputs.tinted-schemes + "/base16/phd.yaml";
        opacity.terminal = 0.9;

        fonts = {
          monospace = {
            name = "Monaco Nerd Font";
            package = pkgs.my.monaco-nerd-font;
          };
          sizes.applications = 10;
        };
      };
    };
in
{
  flake.nixosModules.cli-environment.imports = [
    inputs.stylix.nixosModules.stylix
    stylixConfig
  ];

  flake.darwinModules.cli-environment.imports = [
    inputs.stylix.darwinModules.stylix
    stylixConfig
  ];

  flake.homeModules.cli-environment = args: {
    # Embedded Home Manager gets Stylix and its settings from the system integration.
    imports = lib.optionals (!(args ? osConfig)) [
      inputs.stylix.homeModules.stylix
      stylixConfig
    ];
  };
}
