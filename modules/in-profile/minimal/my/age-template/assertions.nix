# Eval-time checks on every entry in `my.age-template.files`.
{ lib }:
let
  # Get the `$name` and `${name}` a template asks for. The render script parses the
  # same shape at run time, and refuses to write a file with one left over.
  placeholdersOf =
    content:
    lib.unique (
      lib.concatMap (m: lib.optionals (lib.isList m) (lib.filter (x: x != null) m)) (
        builtins.split "[$][{]([a-zA-Z_][a-zA-Z0-9_]*)[}]|[$]([a-zA-Z_][a-zA-Z0-9_]*)" content
      )
    );
in
files:
lib.concatLists (
  lib.mapAttrsToList (
    name: entry:
    let
      about = ''my.age-template.files."${name}"'';
      list = lib.concatMapStringsSep ", " (v: "$" + v);

      asked = placeholdersOf entry.content;
      given = lib.attrNames entry.placeholders;
      malformed = lib.filter (v: lib.match "[a-zA-Z_][a-zA-Z0-9_]*" v == null) given;
    in
    [
      {
        # The name is spliced into the render script and into the sweep's `-name`
        # patterns. No leading dot either: the sweep spares `.render-*`, and would
        # spare this file too long after it stopped being declared.
        assertion = lib.match "[A-Za-z0-9_-][A-Za-z0-9._-]*" name != null;
        message = "${about}: the name is one plain file name, not a path or a pattern.";
      }
    ]
    ++ (
      if malformed != [ ] then
        # Alone, since a name the template cannot spell fails the rest as well.
        [
          {
            assertion = false;
            message = "${about}: ${list malformed} is not a variable name.";
          }
        ]
      else
        # The two directions of one question. Whole names throughout: a placeholder
        # called `access` is not used by $accessToken.
        [
          {
            assertion = lib.subtractLists given asked == [ ];
            message = "${about}: nothing provides ${list (lib.subtractLists given asked)}.";
          }
          {
            assertion = lib.subtractLists asked given == [ ];
            message = "${about}: the template never uses ${list (lib.subtractLists asked given)}.";
          }
        ]
    )
  ) files
)
