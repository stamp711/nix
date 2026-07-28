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
    _:
    let
      localSkills = importSkills ./skills;

      skills = localSkills;

    in
    {
      programs.claude-code = {
        enable = true;
        enableMcpIntegration = true;
        inherit skills;

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
      };
      # Let codex own this file, since it really wants to mutate it at runtime.
      home.file.".codex/config.toml".enable = false;

      programs.opencode = {
        enable = true;
        enableMcpIntegration = true;
        inherit skills;
      };

      programs.pi-coding-agent.enable = true;

      programs.mcp.enable = true;
      programs.mcp.servers = { };
    };
}
