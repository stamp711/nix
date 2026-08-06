# Files rendered from decrypted secrets, one per entry in `my.age-template.files`.
# What a consumer may set is in file-type.nix, what is refused before activation in
# assertions.nix, how one file is written in render-script.nix, and how all of them
# are in render-all.nix.
{ lib, self, ... }:
let
  fileType = import ./file-type.nix { inherit lib self; };
  mkAssertions = import ./assertions.nix { inherit lib; };
  mkRenderAll = import ./render-all.nix { inherit lib; };

  # Decrypted path -> the source ciphertext it is kept in.
  # agenix-rekey's output sits in a store path of the whole node, and moves
  # whenever any other secret of the same host does.
  ciphertextsOf =
    secrets:
    lib.listToAttrs (
      map (s: lib.nameValuePair (toString s.path) (s.rekeyFile or s.file)) (lib.attrValues secrets)
    );
in
{
  flake.nixosModules.my =
    { config, pkgs, ... }:
    let
      cfg = config.my.age-template;
      dirScript = "dir=${lib.escapeShellArg cfg.filesDir}";
      # Traversable, since the services that read these run as other users.
      dirMode = "0701";
      renderAll = mkRenderAll {
        inherit pkgs dirScript dirMode;
        inherit (cfg) files;
      };
    in
    {
      options.my.age-template = {
        filesDir = lib.mkOption {
          type = lib.types.str;
          default = "/run/age-template";
          description = "Folder where the rendered files are written.";
        };

        files = lib.mkOption {
          type = lib.types.attrsOf (fileType {
            inherit (cfg) filesDir;
            ownable = true;
            ciphertexts = ciphertextsOf config.age.secrets;
            sharedScriptArgs = { inherit pkgs dirScript dirMode; };
          });
          default = { };
          description = "Attrset of templates, rendered from decrypted secrets during activation.";
        };
      };

      config = lib.mkIf (cfg.files != { }) {
        assertions = mkAssertions cfg.files;

        system.activationScripts.age-template = lib.stringAfter [ "etc" "agenix" ] "${renderAll}";
      };
    };

  flake.homeModules.my =
    { config, pkgs, ... }:
    let
      cfg = config.my.age-template;
      inherit (pkgs.stdenv.hostPlatform) isDarwin;

      # The per-user runtime directory, where agenix keeps its own secrets.
      # macOS has no XDG_RUNTIME_DIR, and this is the closest thing it has.
      # An empty base would put the files in the root, so refuse instead.
      dirScript =
        if isDarwin then
          ''
            base="$(${lib.getExe pkgs.getconf} DARWIN_USER_TEMP_DIR)"
            dir="''${base:?age-template: DARWIN_USER_TEMP_DIR is empty}/age-template"
          ''
        else
          ''dir="''${XDG_RUNTIME_DIR:?age-template: XDG_RUNTIME_DIR is not set}/age-template"'';

      # The user's own, so it need not be traversed by anyone else.
      dirMode = "0700";

      renderAll = mkRenderAll {
        inherit pkgs dirScript dirMode;
        inherit (cfg) files;
      };
    in
    {
      options.my.age-template = {
        filesDir = lib.mkOption {
          type = lib.types.str;
          default = "${config.xdg.dataHome}/age-template";
          defaultText = lib.literalMD "`age-template` below {env}`XDG_DATA_HOME`";
          description = ''
            Folder where the rendered files are symlinked to, as
            {option}`age.secretsDir` is for the secrets themselves. They are written
            to a per-user runtime directory.
          '';
        };

        files = lib.mkOption {
          type = lib.types.attrsOf (fileType {
            inherit (cfg) filesDir;
            ownable = false;
            ciphertexts = ciphertextsOf config.age.secrets;
            sharedScriptArgs = {
              inherit pkgs dirScript dirMode;
              # The link the files are read through, made by whoever renders first.
              linkDir = cfg.filesDir;
            };
          });
          default = { };
          description = "Attrset of templates, rendered from decrypted secrets.";
        };
      };

      config = lib.mkIf (cfg.files != { }) {
        assertions = mkAssertions cfg.files;

        systemd.user.services.age-template = {
          Unit = {
            Description = "Render age templates";
            After = [ "agenix.service" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${renderAll}";
          };
          Install.WantedBy = [ "default.target" ];
        };

        launchd.agents.age-template = {
          enable = true;
          config = {
            ProgramArguments = [ "${renderAll}" ];
            RunAtLoad = true;
            # Failing is how we wait: launchd cannot order us after agenix.
            KeepAlive.SuccessfulExit = false;
          };
        };
      };
    };
}
