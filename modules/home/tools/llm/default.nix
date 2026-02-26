{
  description = "LLM coding assistants";

  module = {
    programs.claude-code = {
      enable = true;
      enableMcpIntegration = true;

      settings = {
        permissions = {
          allow = [
            "WebSearch"
            "WebFetch"
            "mcp__claude_ai_DeepWiki__read_wiki_structure"
            "mcp__claude_ai_DeepWiki__read_wiki_contents"
            "mcp__claude_ai_DeepWiki__ask_question"
          ];
        };
        statusLine = {
          type = "command";
          command = "bash ${./statusline.sh}";
        };
      };

      skillsDir = ./skills;
    };

    programs.codex.enable = true;

    programs.gemini-cli.enable = true;

    programs.opencode.enable = true;
    programs.opencode.enableMcpIntegration = true;

    programs.mcp.enable = true;
    programs.mcp.servers = {
      github = {
        type = "http";
        url = "https://api.githubcopilot.com/mcp/";
      };
    };
  };
}
