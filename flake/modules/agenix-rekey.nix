{ inputs, ... }:
let
  agenix-rekey =
    {
      lib,
      self,
      config,
      ...
    }:
    let
      hasRekey = _: cfg: (cfg.config ? age) && (cfg.config.age ? rekey);

      # all configs
      nixos = config.flake.nixosConfigurations or { };
      containers = lib.concatMapAttrs (
        host: cfg:
        lib.mapAttrs' (cname: c: lib.nameValuePair "${host}-${cname}" { inherit (c) config; }) (
          cfg.config.containers or { }
        )
      ) nixos;
      darwin = config.flake.darwinConfigurations or { };
      home = config.flake.homeConfigurations or { };

      # config that has rekey (feed into agenix-rekey.configure)
      rekeyNixos = lib.filterAttrs hasRekey nixos;
      rekeyContainers = lib.filterAttrs hasRekey containers;
      rekeyDarwin = lib.filterAttrs hasRekey darwin;
      rekeyHome = lib.filterAttrs hasRekey home;

      # HM embedded in a nixos/darwin/containers
      hosts = self.lib.mergeDisjoint [
        nixos
        containers
        darwin
      ];
      homeInHosts = lib.concatMapAttrs (
        name: cfg:
        lib.mapAttrs' (u: uc: lib.nameValuePair "${name}-${u}" { config = uc; }) (
          cfg.config.home-manager.users or { }
        )
      ) hosts;

      # embedded HM that has rekey (only for checks)
      rekeyHomeInHost = lib.filterAttrs hasRekey homeInHosts;

      extractExpectedFiles =
        configurations:
        lib.concatLists (
          lib.mapAttrsToList (
            _: cfg:
            let
              inherit (cfg.config.age) secrets;
              # The directory the node itself names, so this cannot drift from the real one.
              node = baseNameOf cfg.config.age.rekey.localStorageDir;
              # Secrets without a rekeyFile are plain agenix ones; does not belong to agenix-rekey.
              rekeyed = lib.filterAttrs (_: s: (s.rekeyFile or null) != null) secrets;
            in
            # s.file is where the rekeyed secret has to land.
            lib.mapAttrsToList (_: s: "${node}/${baseNameOf (toString s.file)}") rekeyed
          ) configurations
        );

      expectedFiles = lib.unique (
        extractExpectedFiles rekeyNixos
        ++ extractExpectedFiles rekeyContainers
        ++ extractExpectedFiles rekeyDarwin
        ++ extractExpectedFiles rekeyHome
        ++ extractExpectedFiles rekeyHomeInHost
      );

      listFiles =
        dir: prefix:
        lib.concatLists (
          lib.mapAttrsToList (
            name: type:
            # prefix carries the path back down, so names come out relative to the first dir.
            if type == "directory" then
              listFiles "${dir}/${name}" "${prefix}${name}/"
            else
              [ "${prefix}${name}" ]
          ) (builtins.readDir dir)
        );

      # Both sides are "<node dir>/<file>", so a secret in the wrong node's directory fails.
      actualFiles = lib.optionals (builtins.pathExists self.lib.rekeyRoot) (
        listFiles self.lib.rekeyRoot ""
      );

      missing = lib.filter (f: !builtins.elem f actualFiles) expectedFiles;
      unexpected = lib.filter (f: !builtins.elem f expectedFiles) actualFiles;
    in
    {
      flake.agenix-rekey = inputs.agenix-rekey.configure {
        userFlake = self;
        nixosConfigurations = self.lib.mergeDisjoint [
          rekeyNixos
          rekeyContainers
        ];
        darwinConfigurations = rekeyDarwin;
        homeConfigurations = rekeyHome;
      };

      perSystem =
        { pkgs, ... }:
        {
          checks.agenix-rekey =
            let
              msg =
                lib.optionalString (
                  missing != [ ]
                ) "Missing rekeyed secrets: ${builtins.concatStringsSep ", " missing}\n"
                + lib.optionalString (
                  unexpected != [ ]
                ) "Unexpected files in .rekey/: ${builtins.concatStringsSep ", " unexpected}\n"
                + "Run 'agenix rekey' to fix.";
            in
            assert missing == [ ] && unexpected == [ ] || throw msg;
            pkgs.runCommand "agenix-rekey-check" { } "touch $out";
        };
    };
in
{
  flake.flakeModules.agenix-rekey = agenix-rekey;

  imports = [ agenix-rekey ];
}
