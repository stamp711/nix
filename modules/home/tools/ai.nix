{
  description = "AI coding assistants";

  module = {
    programs.claude-code.enable = true;
    programs.claude-code.enableMcpIntegration = true;

    programs.codex.enable = true;

    programs.gemini-cli.enable = true;

    programs.opencode.enable = true;
    programs.opencode.enableMcpIntegration = true;

    programs.mcp.enable = true;
    programs.mcp.servers = { };
  };
}
