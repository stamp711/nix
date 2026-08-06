# What to answer when an agent is about to run a command, said once for all of them.
# A rule is a shape of command and an answer for it; `check` is the rules made a program.
# Declared in every module class, because the agents are configured from different ones.
{ lib, self, ... }:
let
  policy =
    { config, pkgs, ... }:
    let
      yaml = pkgs.formats.yaml { };

      # A decision as ast-grep can carry it, which is as a severity.
      severities = {
        deny = "error";
        ask = "warning";
        note = "info";
      };

      # The rules as the directory ast-grep scans.
      ruleDir = pkgs.runCommand "bash-policy-rules" { } ''
        mkdir -p $out/rules
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: entry: ''
            cp ${
              yaml.generate "${name}.yml" {
                id = name;
                language = "bash";
                severity = severities.${entry.decision};
                inherit (entry) message;
                rule = entry.match;
              }
            } "$out/rules/${name}.yml"
          '') config.my.llm-agents.bash-policy.rules
        )}
        cp ${yaml.generate "sgconfig.yml" { ruleDirs = [ "rules" ]; }} $out/sgconfig.yml
      '';
    in
    {
      options.my.llm-agents.bash-policy = {
        rules = lib.mkOption {
          default = { };
          description = "Commands to answer for, by what they are rather than how they read.";
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                message = lib.mkOption {
                  type = lib.types.str;
                  description = "What the agent is told. Where it is stopped, say what to do instead.";
                };

                match = lib.mkOption {
                  type = lib.types.attrsOf lib.types.anything;
                  description = "An ast-grep rule, as its `rule:` key.";
                };

                decision = lib.mkOption {
                  # `allow` is left out: it skips the permission system rather than passing it.
                  type = lib.types.enum [
                    "deny"
                    "ask"
                    "note"
                  ];
                  default = "deny";
                  description = ''
                    Refuse the command, put it to the human, or let it run and say this
                    alongside it.
                  '';
                };
              };
            }
          );
        };

        check = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          default = pkgs.writeShellScriptBin "bash-policy-check" ''
            exec ${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.bash-policy-check} \
              --rules ${ruleDir} "$@"
          '';
          defaultText = lib.literalMD "{command}`bash-policy-check` holding these {option}`rules`";
          description = ''
            Reads a command on stdin. Exits 0 when no rule matches, 1 with
            `{"decision":…,"reason":…}` on stdout when one does, and 2 when it could
            not tell. The strictest matching rule is the one answered with.
          '';
        };
      };
    };

  # The hook an agent runs before every command.
  # Payload on stdin, verdict back as the JSON it expects. One script for both agents,
  # because both hold the command in tool_input.command and read the same answer.
  hook =
    { config, pkgs }:
    pkgs.writeShellScript "bash-policy-hook" ''
      command=$(${lib.getExe pkgs.jq} -r '.tool_input.command // empty') || exit 0
      [ -n "$command" ] || exit 0

      # A command it could not judge stops nothing.
      verdict=$(printf '%s' "$command" | ${lib.getExe config.my.llm-agents.bash-policy.check}) && exit 0
      [ -n "$verdict" ] || exit 0

      printf '%s' "$verdict" | ${lib.getExe pkgs.jq} '{
        hookSpecificOutput: { hookEventName: "PreToolUse" } + (
          if .decision == "note"
          then { additionalContext: .reason }
          else { permissionDecision: .decision, permissionDecisionReason: .reason }
          end
        )
      }'
    '';

  claude =
    { config, pkgs, ... }:
    lib.mkIf (config.my.llm-agents.bash-policy.rules != { }) {
      programs.claude-code.settings.hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "${hook { inherit config pkgs; }}";
            }
          ];
        }
      ];
    };

  codex =
    { config, pkgs, ... }:
    lib.mkIf (config.my.llm-agents.bash-policy.rules != { }) {
      my.codex.managedHooks.bash-policy = {
        event = "PreToolUse";
        # In a hook payload codex calls all of its shell tools `Bash`, code mode included.
        matcher = "Bash";
        command = hook { inherit config pkgs; };
      };
    };
in
{
  flake.homeModules.my = {
    imports = [
      policy
      claude
    ];
  };

  flake.nixosModules.my = {
    imports = [
      policy
      codex
    ];
  };

  flake.darwinModules.my = {
    imports = [
      policy
      codex
    ];
  };
}
