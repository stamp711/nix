{ lib, ... }:
{
  flake.homeModules.my =
    { config, ... }:
    let
      skillFiles =
        root:
        lib.mapAttrs' (
          name: source:
          lib.nameValuePair "${root}/${name}" {
            inherit source;
            recursive = true;
          }
        ) config.my.llm.skills;
    in
    {
      options.my.llm.skills = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.oneOf [
            lib.types.path
            lib.types.str
          ]
        );
        default = { };
        description = ''
          Shared skill directories for LLM coding agents.

          Each value is a directory containing a `SKILL.md` and any supporting
          files. Sources are linked without evaluation-time filesystem checks,
          so derivation output paths are supported.
        '';
      };

      # Codex, Pi, and OpenCode use .agents; Claude and OpenCode use .claude.
      config.home.file = skillFiles ".agents/skills" // skillFiles ".claude/skills";
    };
}
