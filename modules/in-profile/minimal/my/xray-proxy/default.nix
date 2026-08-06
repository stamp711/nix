{ self, ... }:
let
  # What `agenix generate` runs to make a secret that does not exist yet.
  uuidgen = { pkgs, ... }: "${pkgs.util-linux}/bin/uuidgen";

  generators = {
    VLESS_UUID.script = uuidgen;
    VMESS_UUID.script = uuidgen;
    TROJAN_PASSWORD.script = "alnum";
  };

  pathNames = [
    "VLESS_PATH"
    "VMESS_PATH"
    "TROJAN_PATH"
  ];
in
{
  flake.nixosModules.my =
    { config, lib, ... }:
    let
      cfg = config.my.xray-proxy;
      # One agenix secret per value, each named after its own ciphertext.
      secretNames = lib.mapAttrs (_: self.lib.ageSecretName) cfg.secrets;
      secretPaths = lib.mapAttrs (_: secret: config.age.secrets.${secret}.path) secretNames;

      # The decrypted paths for the names a template uses, and nothing else.
      placeholdersFor = names: lib.getAttrs names secretPaths;

      # Replaces `$VLESS_PATH` and `${VLESS_PATH}` in a template with the path
      # configured under that name, and the same for the other pathNames.
      # They are not secret, so they need not go through the render script.
      substitutePaths =
        let
          paths = lib.getAttrs pathNames cfg.paths;
        in
        builtins.replaceStrings
          (lib.concatMap (n: [
            "\${${n}}"
            ("$" + n)
          ]) pathNames)
          (
            lib.concatMap (n: [
              paths.${n}
              paths.${n}
            ]) pathNames
          );
    in
    {
      options.my.xray-proxy = {
        enable = lib.mkEnableOption "Xray proxy with Caddy";
        openFirewall = lib.mkEnableOption "Open TCP port 443 in the firewall";
        paths = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          example = lib.literalExpression ''{ VLESS_PATH = "/api/v2/events"; }'';
          description = "The URL path each protocol is served under: ${lib.concatStringsSep ", " pathNames}.";
        };
        secrets = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          example = lib.literalExpression "{ DOMAIN = ./domain.age; }";
          description = ''
            The `.age` file behind each name the templates use, one value per file:
            DOMAIN, CAMOUFLAGE, the two UUIDs and the trojan password. The templates
            say which; a name they never use is an error.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        age.secrets = lib.mapAttrs' (
          name: secret:
          lib.nameValuePair secret (
            self.lib.mergeDisjoint [
              { rekeyFile = cfg.secrets.${name}; }
              (lib.optionalAttrs (generators ? ${name}) { generator = generators.${name}; })
            ]
          )
        ) secretNames;

        # Caddy
        my.age-template.files."Caddyfile" = {
          placeholders = placeholdersFor [
            "DOMAIN"
            "CAMOUFLAGE"
          ];
          content = substitutePaths (builtins.readFile ./Caddyfile.template);
          owner = "caddy";
          group = "caddy";
        };
        services.caddy = {
          enable = true;
          configFile = config.my.age-template.files."Caddyfile".path;
        };
        # A path in this repo is a subpath of the whole flake source, so every
        # unrelated edit would reload us.
        systemd.services.caddy.reloadTriggers = [
          config.my.age-template.files."Caddyfile".renderedFileHash
        ];

        # Xray
        my.age-template.files."xray-config.json" = {
          placeholders = placeholdersFor [
            "VLESS_UUID"
            "VMESS_UUID"
            "TROJAN_PASSWORD"
          ];
          content = substitutePaths (builtins.readFile ./xray-config.json.template);
        };
        services.xray = {
          enable = true;
          settingsFile = config.my.age-template.files."xray-config.json".path;
        };
        systemd.services.xray.restartTriggers = [
          config.my.age-template.files."xray-config.json".renderedFileHash
        ];

        # Firewall
        networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 443 ];
      };
    };
}
