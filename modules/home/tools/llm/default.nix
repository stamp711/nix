{
  description = "LLM coding assistants";

  module =
    { pkgs, ... }:
    let
      inherit (pkgs) llm-agents;
    in
    {
      programs.claude-code = {
        enable = true;
        package = llm-agents.claude-code;
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
      programs.codex.package = llm-agents.codex;
      programs.codex.enableMcpIntegration = true;

      programs.gemini-cli.enable = true;
      programs.gemini-cli.package = llm-agents.gemini-cli;

      programs.opencode.enable = true;
      programs.opencode.package = llm-agents.opencode;
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
