# https://atuin.sh/atuin-for-agents/
{ lib, ... }:
let
  codexHookModule =
    { pkgs, ... }:
    {
      my.codex.managedHooks.atuin-record = {
        events = [
          "PreToolUse"
          "PostToolUse" # closes failed commands as well
        ];
        matcher = "Bash";
        command = pkgs.writeShellScript "atuin-hook-codex" ''
          exec ${lib.getExe pkgs.atuin} hook codex
        '';
      };
    };
in
{
  flake.nixosModules.cli-programs = codexHookModule;
  flake.darwinModules.cli-programs = codexHookModule;

  flake.homeModules.cli-programs =
    { config, ... }:
    let
      atuin = lib.getExe config.programs.atuin.package;
    in
    {
      programs.claude-code.settings = {
        hooks =
          let
            h = {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "${atuin} hook claude-code";
                }
              ];
            };
          in
          {
            PreToolUse = [ h ];
            PostToolUse = [ h ];
            PostToolUseFailure = [ h ];
          };
        permissions.allow = [
          "mcp__atuin__atuin_history"
          "mcp__atuin__atuin_output"
        ];
      };

      programs.mcp.servers.atuin = {
        command = atuin;
        args = [ "mcp" ];
      };
    };
}
