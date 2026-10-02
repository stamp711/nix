# LLM coding assistants
{
  flake.homeModules.cli-programs = {

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
  };
}
