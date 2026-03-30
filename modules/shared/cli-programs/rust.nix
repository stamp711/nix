{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        cargo-expand
        cargo-feature
        cargo-generate
        cargo-nextest
        cargo-watch
        rustup
      ];

    };

}
