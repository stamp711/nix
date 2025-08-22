{ pkgs, ... }:
{
  home.packages = with pkgs; [
    treefmt
    nixfmt
    clang-tools
    gersemi
  ];
  home.file.".treefmt.toml".source = (pkgs.formats.toml { }).generate "treefmt.toml" {

    # ---------- Nix ----------
    formatter.nixfmt = {
      command = "nixfmt";
      includes = [
        "**/*.nix"
      ];
    };

    # ---------- C/C++ ----------
    formatter.clang-format = {
      command = "clang-format";
      options = [ "-i" ];
      includes = [
        "**/*.c"
        "**/*.h"
        "**/*.cpp"
        "**/*.hpp"
        "**/*.cc"
      ];
    };

    # ---------- CMake ----------
    formatter.gersemi = {
      command = "gersemi";
      options = [ "-i" ];
      includes = [
        "**/CMakeLists.txt"
        "**/*.cmake"
      ];
    };
  };
}
