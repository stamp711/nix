# Load annotation files and expand relative includes in order before selecting
# settings. Text parsing and policy selection live in parse.nix.
{ lib }:
{
  file,
  arch,
  flavour ? "nvidia",
}:
let
  parser = import ./parse.nix { inherit lib; };
  readDocument = path: parser.parseText (builtins.readFile path);
  root = readDocument file;

  expandIncludes =
    stack: path: document:
    let
      # Only the cycle-detection key drops context; reads keep the source dependency.
      key = toString (/. + builtins.unsafeDiscardStringContext (toString path));
    in
    builtins.addErrorContext "while loading annotations from ${toString path}" (
      if builtins.elem key stack then
        throw "Cyclic annotations include: ${toString path}"
      else
        lib.concatMap (
          entry:
          if entry ? include then
            let
              child = "${builtins.dirOf (toString path)}/${entry.include}";
            in
            expandIncludes (stack ++ [ key ]) child (readDocument child)
          else
            [ entry ]
        ) document.entries
    );
in
parser.selectConfig {
  inherit (root) headers;
  policies = expandIncludes [ ] file root;
  inherit arch flavour;
}
