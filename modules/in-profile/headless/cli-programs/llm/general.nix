# LLM coding assistants
{ lib, ... }:
let
  importSkills =
    root:
    lib.mapAttrs' (name: _: lib.nameValuePair name (root + "/${name}")) (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir root)
    );
  skills = importSkills ./skills;
in
{
  flake.homeModules.cli-programs = {
    my.llm-agents.skills = skills;

    programs.mcp.enable = true;
    programs.mcp.servers = { };
  };
}
