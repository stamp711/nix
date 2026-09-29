# Pure parsing and selection of Ubuntu/NVIDIA format-4 annotations.
# Includes are returned as entries; resolving them belongs to the file loader.
{ lib }:
let
  inherit (builtins)
    concatStringsSep
    elemAt
    filter
    foldl'
    fromJSON
    head
    isString
    match
    split
    toJSON
    ;

  normaliseLine =
    line: concatStringsSep " " (filter (s: isString s && s != "") (split "[ \t\r]+" line));
  # Policy dictionaries contain Python string literals, including quoted
  # Kconfig strings. Tokenise those before converting the dictionary to JSON;
  # replacing all apostrophes with double quotes would corrupt their values.
  decodePythonString =
    token:
    let
      inner = builtins.substring 1 (builtins.stringLength token - 2) token;
      escapes = {
        "\\" = "\\";
        "'" = "'";
        "\"" = "\"";
        n = "\n";
        r = "\r";
        t = "\t";
      };
    in
    concatStringsSep "" (
      map (
        part:
        if isString part then
          part
        else
          escapes.${head part} or (throw "Unsupported annotations escape: \\${head part}")
      ) (split "\\\\(.)" inner)
    );

  parseStringDict =
    text:
    let
      tokens = split "('([^'\\\\]|\\\\.)*'|\"([^\"\\\\]|\\\\.)*\")" text;
      result = fromJSON (
        concatStringsSep "" (
          map (part: if isString part then part else toJSON (decodePythonString (head part))) tokens
        )
      );
      literals = filter builtins.isList tokens;
    in
    if builtins.isAttrs result && lib.all isString (builtins.attrValues result) then
      {
        values = result;
        keys = builtins.genList (i: decodePythonString (head (elemAt literals (2 * i)))) (
          builtins.div (builtins.length literals) 2
        );
      }
    else
      throw "Expected a string dictionary in annotations: ${text}";

  parseText =
    text:
    let
      lines = map normaliseLine (lib.splitString "\n" text);
      readHeader =
        name: default:
        let
          values = filter (value: value != null) (map (match "# ${name}: (.*)") lines);
        in
        if values == [ ] then default else head (lib.last values);
    in
    {
      headers = {
        format = readHeader "FORMAT" "";
        architectures = lib.splitString " " (readHeader "ARCH" "");
        flavours = lib.splitString " " (readHeader "FLAVOUR" "");
        flavourDependencies = (parseStringDict (readHeader "FLAVOUR_DEP" "{}")).values;
      };
      entries = lib.concatMap (
        line:
        let
          include = match "include \"([^\"]+)\"" line;
          policy = match "(CONFIG_[A-Za-z0-9_]+) policy<([^>]*)>(.*)" line;
          note = match "CONFIG_[A-Za-z0-9_]+ note<.*" line;
        in
        if line == "" || lib.hasPrefix "#" line || note != null then
          [ ]
        else if include != null then
          [ { include = head include; } ]
        else if policy != null then
          [
            {
              name = head policy;
              value = parseStringDict (elemAt policy 1);
            }
          ]
        else
          throw "Invalid annotations line: ${line}"
      ) lines;
    };

  selectConfig =
    {
      headers,
      policies,
      arch,
      flavour ? "nvidia",
    }:
    let
      inherit (headers) architectures flavours flavourDependencies;
      targetFlavour = "${arch}-${flavour}";
      parentFlavour = flavourDependencies.${targetFlavour} or targetFlavour;
      mergePolicy =
        old: entry:
        # Python dictionaries preserve insertion order. A later architecture-wide
        # assignment also clears flavour assignments earlier in the same policy.
        foldl' (
          policy: key:
          (
            if builtins.elem key architectures then
              lib.filterAttrs (name: _: !(lib.hasPrefix key name)) policy
            else
              policy
          )
          // {
            ${key} = entry.value.values.${key};
          }
        ) old entry.value.keys;
      policiesBySymbol = builtins.groupBy (entry: entry.name) policies;
      values = lib.mapAttrs (
        _: entries:
        let
          policy = foldl' mergePolicy { } entries;
        in
        policy.${targetFlavour} or policy.${parentFlavour} or policy.${arch} or "-"
      ) policiesBySymbol;
    in
    assert lib.assertMsg (headers.format == "4") "Unsupported NVIDIA annotations format";
    assert lib.assertMsg (builtins.elem arch architectures)
      "Unknown NVIDIA annotations architecture: ${arch}";
    assert lib.assertMsg (builtins.elem targetFlavour flavours)
      "Unknown NVIDIA annotations flavour: ${targetFlavour}";
    lib.filterAttrs (_: value: value != "-") values;
in
{
  inherit parseText selectConfig;
}
