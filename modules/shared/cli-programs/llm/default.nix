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
      inherit (pkgs) llm-agents;

      allowRead = pattern: [
        "Read(${pattern})"
        "Glob(${pattern})"
        "Grep(${pattern})"
        "Bash(ls ${pattern})"
        "Bash(cat ${pattern})"
      ];

      localSkills = importSkills ./skills;
      cavemanSkills = importSkills (inputs.caveman + "/skills");
      hunkSkills = importSkills (inputs.hunk + "/skills");

      skills = cavemanSkills // hunkSkills // localSkills;
    in
    {
      programs.claude-code = {
        enable = true;
        package = llm-agents.claude-code;
        enableMcpIntegration = true;
        inherit skills;

        settings = {
          effortLevel = "high";
          tui = "fullscreen";
          worktree.bgIsolation = "none";
          permissions = {
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

      programs.opencode = {
        enable = true;
        package = llm-agents.opencode;
        enableMcpIntegration = true;
        inherit skills;
      };

      programs.codex = {
        enable = true;
        package = llm-agents.codex;
        enableMcpIntegration = true;
        inherit skills;
      };

      # programs.gemini-cli = {
      #   enable = true;
      #   package = llm-agents.gemini-cli;
      # };

      programs.mcp.enable = true;
      programs.mcp.servers = {
        # github = {
        #   type = "http";
        #   url = "https://api.githubcopilot.com/mcp/";
        # };
      };
    };
}
