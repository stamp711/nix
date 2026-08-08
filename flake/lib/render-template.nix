{ lib, ... }:
{
  flake.lib = {
    # Fill every `@name@` in a template file with the string given under that name.
    # A `$name` is left alone, for whoever renders the layer after this one.
    renderTemplate =
      file: replacements:
      let
        text = builtins.readFile file;
        # Every `@name@` the template asks for. The character class is the one
        # nixpkgs' own substitution accepts.
        asked = lib.unique (
          lib.concatMap (m: lib.optionals (lib.isList m) m) (
            builtins.split "@([A-Za-z_][0-9A-Za-z_'-]*)@" text
          )
        );
        given = lib.attrNames replacements;
        list = lib.concatMapStringsSep ", " (n: "@${n}@");
        missing = lib.subtractLists given asked;
        unused = lib.subtractLists asked given;
      in
      if missing != [ ] then
        throw "renderTemplate: ${toString file}: nothing provides ${list missing}"
      else if unused != [ ] then
        throw "renderTemplate: ${toString file}: the template never uses ${list unused}"
      else
        builtins.replaceStrings (map (n: "@${n}@") given) (map (n: replacements.${n}) given) text;
  };
}
