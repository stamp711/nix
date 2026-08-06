# The type of one entry in `my.age-template.files`: what a consumer sets, plus the
# path, hash and render script derived from it. Its arguments are the whole of what
# NixOS and home-manager do differently.
{ lib, self }:
let
  mkRenderScript = import ./render-script.nix;
in
{
  # Where the file is read from, which on home-manager is the link.
  filesDir,
  # Whether owner and group are declared at all.
  ownable,
  # Decrypted path -> the encrypted file behind it, from age.secrets.
  ciphertexts,
  # The half of the render script that is the same for every file here; the
  # other half is the file's own options.
  sharedScriptArgs,
}:
lib.types.submodule (
  { name, config, ... }:
  {
    # The two halves must be disjoint: a name in both is an error.
    options = self.lib.mergeDisjoint [
      {
        placeholders = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = ''
            Placeholder name to the decrypted file its value comes from, used in
            the template as `$name` or `''${name}`. The value is substituted
            verbatim, so a secret holding the target format's metacharacters is
            not escaped.
          '';
        };

        content = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = ''
            Content of the template. `$name` and `''${name}` are replaced by
            the contents of {option}`placeholders`.`name`.
          '';
        };

        mode = lib.mkOption {
          type = lib.types.str;
          default = "0400";
          description = "Permissions mode of the rendered file in a format understood by chmod.";
        };

        path = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = "${filesDir}/${name}";
          defaultText = lib.literalMD "this file below {option}`my.age-template.filesDir`";
          description = ''
            Path where the rendered file is installed. To place it somewhere a
            reader insists on, link that path to this one with `home.file` or
            `environment.etc`.
          '';
        };

        renderedFileHash = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          default = builtins.hashString "sha256" (
            builtins.unsafeDiscardStringContext (
              builtins.toJSON (
                self.lib.mergeDisjoint [
                  { inherit (config) content mode; }
                  # A hash of each ciphertext's contents, keyed by the name it is used under.
                  {
                    ciphertextHashes = lib.mapAttrs (
                      _: p:
                      let
                        ciphertext = ciphertexts.${toString p} or null;
                      in
                      if ciphertext == null then toString p else builtins.hashFile "sha256" ciphertext
                    ) config.placeholders;
                  }
                  (lib.optionalAttrs ownable { inherit (config) owner group; })
                ]
              )
            )
          );
          defaultText = lib.literalMD "a hash of what this file renders to";
          description = ''
            Hash of what this file renders to: its {option}`content`, the encrypted
            files behind its {option}`placeholders`, and its permissions. Changes
            exactly when the rendered file would, for a consumer's `restartTriggers`.
          '';
        };

        renderScript = lib.mkOption {
          type = lib.types.path;
          readOnly = true;
          # Built in here, where this file's own values are: reaching for them
          # from outside the submodule is what makes it recurse.
          default = mkRenderScript (
            self.lib.mergeDisjoint [
              sharedScriptArgs
              { inherit lib name; }
              {
                inherit (config)
                  content
                  placeholders
                  mode
                  ;
              }
              (lib.optionalAttrs ownable { inherit (config) owner group; })
            ]
          );
          defaultText = lib.literalMD "the render script for this file";
          description = ''
            Renders this file, idempotently. A consumer that needs it fresh at
            startup runs this before exec.
          '';
        };
      }
      (lib.optionalAttrs ownable {
        owner = lib.mkOption {
          type = lib.types.str;
          default = "0";
          description = "User of the rendered file.";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = "0";
          description = "Group of the rendered file.";
        };
      })
    ];
  }
)
