{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { pkgs, ... }:
    {
      treefmt = {
        projectRootFile = null;
        programs.nixfmt.enable = true;
        programs.stylua.enable = true;
        programs.prettier.enable = true;
        programs.clang-format.enable = true;
        settings.formatter.gersemi = {
          command = "${pkgs.gersemi}/bin/gersemi";
          options = [ "-i" ];
          includes = [
            "**/CMakeLists.txt"
            "**/*.cmake"
          ];
        };
      };
    };
}
