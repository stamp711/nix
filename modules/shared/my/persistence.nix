{ inputs, ... }:
{
  flake.nixosModules.my =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.persistence;
      entryType = lib.types.either lib.types.str lib.types.attrs;

      pathOf = entry: if builtins.isString entry then entry else (entry.directory or entry.file);

      systemPaths = map pathOf (cfg.directories ++ cfg.files);
      userPaths = lib.concatMap (
        user: map (e: "/home/${user}/${pathOf e}") (cfg.user.directories ++ cfg.user.files)
      ) cfg.users;
      declaredPaths = systemPaths ++ userPaths ++ cfg.externalPaths;
      declaredFile = pkgs.writeText "persist-declared-paths" (lib.concatStringsSep "\n" declaredPaths);

      auditScript = pkgs.writeShellScriptBin "persistence-audit-orphans" ''
        set -eu
        persist=${cfg.path}
        mapfile -t declared < ${declaredFile}
        audit() {
          local dir="$1" entry rel d
          local is_declared is_parent
          shopt -s nullglob dotglob
          for entry in "$dir"/*; do
            rel="''${entry#$persist}"
            is_declared=0
            is_parent=0
            for d in "''${declared[@]}"; do
              if [ "$rel" = "$d" ]; then is_declared=1; break; fi
              if [[ "$d" == "$rel"/* ]]; then is_parent=1; fi
            done
            if (( is_declared )); then :
            elif (( is_parent )); then audit "$entry"
            else echo "$entry"
            fi
          done
        }
        audit "$persist"
      '';
    in
    {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      options.my.persistence = {
        enable = lib.mkEnableOption "ephemeral root with /persist via impermanence";
        path = lib.mkOption {
          type = lib.types.str;
          default = "/persist";
          description = "Mountpoint backing the persisted state.";
        };
        directories = lib.mkOption {
          type = lib.types.listOf entryType;
          default = [ ];
          description = "Absolute paths to persist (system scope).";
        };
        files = lib.mkOption {
          type = lib.types.listOf entryType;
          default = [ ];
        };
        users = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ config.my.primaryUser ];
          defaultText = lib.literalExpression "[ config.my.primaryUser ]";
          description = "Users whose homes get user.directories/files persisted.";
        };
        user.directories = lib.mkOption {
          type = lib.types.listOf entryType;
          default = [ ];
          description = "Paths under each persisted user's home.";
        };
        user.files = lib.mkOption {
          type = lib.types.listOf entryType;
          default = [ ];
        };
        externalPaths = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Paths under /persist that are used outside the impermanence
            bind-mount machinery (e.g. services.openssh.hostKeys reads
            /persist/etc/ssh directly). Only consulted by the audit tool
            to silence false positives; has no effect on mounts.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        environment.persistence.${cfg.path} = {
          hideMounts = true;
          inherit (cfg) directories files;
          users = lib.listToAttrs (
            map (u: lib.nameValuePair u { inherit (cfg.user) directories files; }) cfg.users
          );
        };
        environment.systemPackages = [ auditScript ];
      };
    };
}
