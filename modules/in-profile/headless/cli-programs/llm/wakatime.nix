# Self-contained WakaTime plugins (node + wakatime-cli pinned for their hooks)
{ inputs, ... }:
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    let
      claude-wakatime-src = inputs.claude-code-wakatime;

      claude-wakatime-plugin-name =
        (builtins.fromJSON (builtins.readFile "${claude-wakatime-src}/.claude-plugin/plugin.json")).name;

      claude-wakatime =
        let
          run = pkgs.writeShellScript "claude-code-wakatime-run" ''
            export PATH=${pkgs.wakatime-cli}/bin:$PATH
            unset NODE_OPTIONS
            exec ${pkgs.nodejs}/bin/node ${claude-wakatime-src}/dist/index.js "$@"
          '';
        in
        pkgs.runCommand "claude-code-wakatime" { } ''
          cp -r ${claude-wakatime-src} $out
          chmod -R +w $out
          install -m755 ${run} $out/scripts/run
        '';

      codex-wakatime =
        let
          src = "${inputs.codex-cli-wakatime}/plugins/codex-cli-wakatime"; # Codex plugin lives in a marketplace subdir
          run = pkgs.writeShellScript "codex-cli-wakatime-run" ''
            export PATH=${pkgs.wakatime-cli}/bin:$PATH
            unset NODE_OPTIONS
            exec ${pkgs.nodejs}/bin/node ${src}/bin/codex-cli-wakatime.js --background
          '';
        in
        pkgs.runCommand "codex-cli-wakatime" { } ''
          cp -r ${src} $out
          chmod -R +w $out
          install -m755 ${run} $out/scripts/run
        '';
    in
    {
      programs.claude-code.plugins.${claude-wakatime-plugin-name} = claude-wakatime;
      # Read the built manifest's name/version instead of derivation metadata (0.0.0).
      programs.codex.plugins = [ "${codex-wakatime}" ];

      # those are raft agent notes, give it a project name, so they don't show as uuid
      home.file.".slock/agents/.wakatime-project".text = "raft-agents";
    };
}
