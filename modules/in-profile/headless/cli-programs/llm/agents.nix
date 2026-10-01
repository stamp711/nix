# LLM coding assistants
{ lib, ... }:
let
  importSkills =
    root:
    lib.mapAttrs' (name: _: lib.nameValuePair name (root + "/${name}")) (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir root)
    );
in
{
  flake.homeModules.cli-programs =
    let
      skills = importSkills ./skills;
    in
    {
      my.llm-agents.skills = skills;

      programs.claude-code = {
        enable = true;
        enableMcpIntegration = true;

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
        # Merge declared settings while allowing Codex to save runtime changes.
        mutableSettings = true;
        settings.tui.theme = "base16-256"; # Use the terminal's Base16 palette, including slots 16–21.
      };

      programs.mcp.enable = true;
      programs.mcp.servers = { };
    };
}
