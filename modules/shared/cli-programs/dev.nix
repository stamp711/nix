# Development tools and language servers
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        # Security
        _1password-cli

        # Python
        uv

        # NodeJS
        volta

        # Language servers
        lua-language-server
        nil
        nixd
        yaml-language-server

        devenv
      ];
    };
}
