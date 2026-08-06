# Refuses the commands that detach a process from its tool call.
# A call's processes are killed by process group when it ends; these three leave that group.
# Nothing here sees a program that calls setsid itself, or a name spelled to hide from a regex.
{ lib, ... }:
let
  rule =
    let
      detach = [
        "nohup"
        "setsid"
        "disown"
      ];

      # Programs that run a command named in their own arguments.
      # The detaching one is a word there, so a bare `nohup` argument is refused too,
      # and a quoted one is a string, which this rule does not look at.
      wrappers = [
        "builtin"
        "command"
        "doas"
        "env"
        "exec"
        "ionice"
        "nice"
        "stdbuf"
        "sudo"
        "time"
        "timeout"
        "xargs"
      ];

      # The name, however quoted, or the last segment of a path to it. Matched against
      # one node's text, so `mynohup` and `nohup.sh` are not it.
      #   - `(^|[/'"\\])` : left bdry: text start, path sep, open quote, or escape
      #   - `(a|b|c)`     : the names
      #   - `['"]?$`      : text ends here, opt close quote
      named = names: ''(^|[/'"\\])(${lib.concatStringsSep "|" names})['"]?$'';
    in
    {
      my.llm-agents.bash-policy.rules.detaching-command = {
        message = ''
          A detached process outlives the tool call with nothing to reap it. Use the
          background option your own tool provides, which you can still see and stop.
        '';

        match.any = [
          {
            kind = "command_name";
            regex = named detach;
          }
          {
            kind = "word";
            regex = named detach;
            inside = {
              kind = "command";
              has = {
                kind = "command_name";
                regex = named wrappers;
              };
            };
          }
        ];
      };
    };
in
{
  flake.homeModules.cli-programs = rule;
  flake.nixosModules.cli-programs = rule;
  flake.darwinModules.cli-programs = rule;
}
