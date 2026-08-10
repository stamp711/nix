# Binary caches: use them as substituters, and serve at most one.
{ self, lib, ... }:
let
  caches = lib.mkOption {
    default = { };
    description = "Binary caches this machine may use or serve, one entry per cache.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            description = "Host the cache answers on.";
          };
          port = lib.mkOption {
            type = lib.types.port;
            # harmonia's own default is 5000, which macOS AirPlay Receiver holds.
            default = 5051;
            description = "Port the cache answers on.";
          };
          keyName = lib.mkOption {
            type = lib.types.str;
            description = "The name this cache's signatures carry, and the name clients trust it under.";
          };
          secretKeyFile = lib.mkOption {
            type = lib.types.path;
            description = ''
              The cache's signing key, encrypted to the machine serving it.

              Its public half sits beside it, the same name with `.pub`.
              `agenix generate` writes both when the file is missing, and a pair made
              elsewhere works just as well.
            '';
          };
          serve = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether this machine is the one serving this cache.";
          };
          allowFromTailnet = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Whether the firewall lets the tailnet reach this cache's port.
              NixOS only, since nix-darwin has no firewall to configure.
            '';
          };
          use = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to use this cache as a substituter, trusting the key it signs with.";
          };
          priority = lib.mkOption {
            type = lib.types.ints.unsigned;
            default = 30;
            description = ''
              Priority of this cache as a substituter, where a lower value means a higher priority.
              cache.nixos.org is 40, so the default puts this one ahead of it.
            '';
          };
        };
      }
    );
  };

  # Where a key's public half sits. The generator writes it there, the client reads it there.
  pubPath = secretKeyFile: lib.removeSuffix ".age" (toString secretKeyFile) + ".pub";

  # The caches this machine uses, and the checks over all of them.
  client =
    cfg:
    let
      # A cache joins these only once `agenix generate` has written its .pub.
      publishedCaches = lib.filterAttrs (_: c: builtins.pathExists (pubPath c.secretKeyFile)) cfg;
      usedCaches = lib.filterAttrs (_: c: c.use) publishedCaches;
      # What a cache publishes, `<name>:<base64>` on one line, and the name out of it.
      publishedKey = c: lib.removeSuffix "\n" (builtins.readFile (pubPath c.secretKeyFile));
      publishedName = c: lib.head (lib.splitString ":" (publishedKey c));
      # The names with two key files under them. Sharing one key is allowed, and this runs
      # before generation, so two files is the closest we can get to two keys.
      namesWithTwoKeyFiles = lib.attrNames (
        lib.filterAttrs (_: cs: lib.length (lib.unique (map (c: toString c.secretKeyFile) cs)) > 1) (
          lib.groupBy (c: c.keyName) (lib.attrValues cfg)
        )
      );
    in
    {
      # An `assert` here would fire while the module system is still collecting attribute
      # names, and reading cfg that early is a loop.
      assertions = [
        {
          assertion = namesWithTwoKeyFiles == [ ];
          message =
            "my.nix.binary-cache: two different keys sign under the name "
            + "${lib.concatStringsSep ", " namesWithTwoKeyFiles}. nix keeps the first key of a name, "
            + "so the other cache's signatures would be rejected.";
        }
      ]
      ++ lib.mapAttrsToList (name: c: {
        assertion = publishedName c == c.keyName;
        message =
          "my.nix.binary-cache.${name}: ${pubPath c.secretKeyFile} publishes ${publishedName c}, "
          + "and keyName says ${c.keyName}. Clients would trust a name nothing signs with.";
      }) publishedCaches;

      warnings =
        lib.mapAttrsToList (
          name: _:
          "my.nix.binary-cache.${name}: this machine both serves and uses this cache. "
          + "A store is searched before any substituter, so every one of those queries is a miss."
        ) (lib.filterAttrs (_: c: c.serve && c.use) cfg)
        ++ lib.mapAttrsToList (
          name: c:
          "my.nix.binary-cache.${name}: nothing published ${pubPath c.secretKeyFile} yet, "
          + "so this machine leaves the cache out until `agenix generate` writes it."
        ) (lib.filterAttrs (name: c: c.use && !(publishedCaches ? ${name})) cfg);

      nix.settings.extra-substituters = lib.mapAttrsToList (
        _: c: "http://${c.host}:${toString c.port}?priority=${toString c.priority}"
      ) usedCaches;
      nix.settings.extra-trusted-public-keys = lib.unique (
        lib.mapAttrsToList (_: publishedKey) usedCaches
      );
    };

  # The cache this machine serves, or null.
  servedCache =
    cfg:
    let
      claimed = lib.attrNames (lib.filterAttrs (_: c: c.serve) cfg);
    in
    if claimed == [ ] then
      null
    else if lib.length claimed == 1 then
      cfg.${lib.head claimed}
    else
      throw (
        "my.nix.binary-cache: this machine claims ${lib.concatStringsSep ", " claimed}, "
        + "and one harmonia serves one store."
      );

  signingKey =
    config: cache:
    self.lib.mkAgeSecret config {
      rekeyFile = cache.secretKeyFile;
      # An agenix generator: the signing key to stdout, its public half beside the .age.
      generator.script =
        { pkgs, file, ... }:
        ''
          dir=$(mktemp -d)
          trap 'rm -rf "$dir"' EXIT
          ${pkgs.nix}/bin/nix-store --generate-binary-cache-key \
            ${lib.escapeShellArg cache.keyName} "$dir/secret" "$dir/public"
          cp "$dir/public" ${lib.escapeShellArg (pubPath file)}
          cat "$dir/secret"
        '';
    };
in
{
  flake.nixosModules.my =
    { config, ... }:
    let
      cache = servedCache config.my.nix.binary-cache;
      key = signingKey config cache;
    in
    {
      options.my.nix.binary-cache = caches;

      config = lib.mkMerge [
        (client config.my.nix.binary-cache)

        (lib.mkIf (cache != null) {
          age.secrets = key.ageSecret;

          services.harmonia.cache = {
            enable = true;
            signKeyPaths = [ key.path ];
            settings.bind = "[::]:${toString cache.port}";
          };

          networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts =
            lib.optional cache.allowFromTailnet cache.port;
        })
      ];
    };

  flake.darwinModules.my =
    { config, pkgs, ... }:
    let
      cache = servedCache config.my.nix.binary-cache;
      key = signingKey config cache;
      settings = (pkgs.formats.toml { }).generate "harmonia.toml" {
        bind = "[::]:${toString cache.port}";
      };
      # nix-store wants a HOME for its temporary cache, and /var/run is cleared at
      # boot, so the job makes its own.
      start = pkgs.writeShellScript "harmonia-start" ''
        set -eu
        install -d -m700 -o root -g wheel /var/run/harmonia
        export HOME=/var/run/harmonia
        exec ${lib.getExe pkgs.harmonia}
      '';
    in
    {
      options.my.nix.binary-cache = caches;

      config = lib.mkMerge [
        (client config.my.nix.binary-cache)

        # nix-darwin has no harmonia module, so the launchd job is ours.
        (lib.mkIf (cache != null) {
          age.secrets = key.ageSecret;

          launchd.daemons.harmonia = {
            command = start;
            serviceConfig = {
              RunAtLoad = true;
              KeepAlive = true;
              # harmonia logs to stdout, and writes only a fatal error to stderr.
              StandardOutPath = "/var/log/harmonia.log";
              StandardErrorPath = "/var/log/harmonia.log";
              EnvironmentVariables = {
                CONFIG_FILE = "${settings}";
                SIGN_KEY_PATHS = key.path;
              };
            };
          };
        })
      ];
    };
}
