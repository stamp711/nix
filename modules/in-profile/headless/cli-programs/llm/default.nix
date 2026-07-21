# LLM coding assistants
{ inputs, lib, ... }:
let
  importSkills =
    root:
    lib.mapAttrs' (name: _: lib.nameValuePair name (root + "/${name}")) (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir root)
    );
in
{
  flake.homeModules.cli-programs =
    { pkgs, ... }:
    let
      localSkills = importSkills ./skills;
      hunkSkills = importSkills (inputs.hunk + "/skills");

      skills = hunkSkills // localSkills;

      # Self-contained WakaTime plugins (node + wakatime-cli pinned for their hooks)
      claude-wakatime =
        let
          src = inputs.claude-code-wakatime;
          run = pkgs.writeShellScript "claude-code-wakatime-run" ''
            export PATH=${pkgs.wakatime-cli}/bin:$PATH
            unset NODE_OPTIONS
            exec ${pkgs.nodejs}/bin/node ${src}/dist/index.js "$@"
          '';
        in
        pkgs.runCommand "claude-code-wakatime" { } ''
          cp -r ${src} $out
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
      programs.claude-code = {
        enable = true;
        enableMcpIntegration = true;
        inherit skills;
        plugins = [ claude-wakatime ];

        settings = {
          theme = "auto";
          tui = "fullscreen";
          effortLevel = "xhigh";
          alwaysThinkingEnabled = true;
          showThinkingSummaries = true;
          permissions =
            let
              allowRead = pattern: [
                "Read(${pattern})"
                "Bash(ls ${pattern})"
                "Bash(cat ${pattern})"
              ];
            in
            {
              allow = [
                "WebSearch"
                "WebFetch"
                "mcp__claude_ai_DeepWiki__read_wiki_structure"
                "mcp__claude_ai_DeepWiki__read_wiki_contents"
                "mcp__claude_ai_DeepWiki__ask_question"
              ]
              ++ allowRead "~/code/**"
              ++ allowRead "~/Developer/**"
              ++ allowRead "/nix/store/**"
              ++ allowRead "/tmp/**";
            };
          statusLine = {
            type = "command";
            command = "bash ${./statusline.sh}";
          };
        };
      };

      programs.codex = {
        enable = true;
        enableMcpIntegration = true;
        inherit skills;
        plugins = [ codex-wakatime ];
      };

      programs.mcp.enable = true;
      programs.mcp.servers = { };
    };
}
