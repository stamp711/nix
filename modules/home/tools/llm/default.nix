{
  description = "LLM coding assistants";

  module =
    { pkgs, ... }:
    let
      inherit (pkgs) llm-agents;

      allowRead = pattern: [
        "Read:${pattern}"
        "Glob:${pattern}"
        "Grep:${pattern}"
      ];
    in
    {
      programs.claude-code = {
        enable = true;
        package = llm-agents.claude-code;
        enableMcpIntegration = true;
        skillsDir = ./skills;

        settings = {
          permissions = {
            allow = [
              "WebSearch"
              "WebFetch"
              "mcp__claude_ai_DeepWiki__read_wiki_structure"
              "mcp__claude_ai_DeepWiki__read_wiki_contents"
              "mcp__claude_ai_DeepWiki__ask_question"
            ]
            ++ allowRead "~/code/**"
            ++ allowRead "/nix/store/**"
            ++ allowRead "/tmp/**";
          };
          statusLine = {
            type = "command";
            command = "bash ${./statusline.sh}";
          };
        };
      };

      programs.opencode = {
        enable = true;
        package = llm-agents.opencode;
        enableMcpIntegration = true;
        skills = ./skills;
      };

      programs.codex = {
        enable = true;
        package = llm-agents.codex;
        enableMcpIntegration = true;
        skills = ./skills;
      };

      programs.gemini-cli = {
        enable = true;
        package = llm-agents.gemini-cli;
      };

      programs.mcp.enable = true;
      programs.mcp.servers = {
        # github = {
        #   type = "http";
        #   url = "https://api.githubcopilot.com/mcp/";
        # };
      };
    };
}
