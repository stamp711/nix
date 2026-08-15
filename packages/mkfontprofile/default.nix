# Builds a .mobileconfig that installs every font in a directory.
{
  perSystem =
    { pkgs, ... }:
    {
      packages.mkfontprofile = pkgs.writers.writePython3Bin "mkfontprofile" {
        # The script is stdlib only; the name table parser stands in for fontTools.
        libraries = [ ];
        # E203 is the slice spacing ruff-format emits and flake8 rejects.
        flakeIgnore = [
          "E203"
          "E501"
        ];
      } (builtins.readFile ./mkfontprofile.py);
    };
}
