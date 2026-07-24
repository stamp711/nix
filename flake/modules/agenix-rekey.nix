{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;

  agenix-rekey =
    { self, config, ... }:
    let
      rekeyDir = self + "/.rekey";

      hasRekey = _: cfg: (cfg.config ? age) && (cfg.config.age ? rekey);

      nixosConfigs = config.flake.nixosConfigurations or { };

      rekeyNixos = lib.filterAttrs hasRekey nixosConfigs;

      # nixos-containers that opt into rekey are their own rekey nodes, like nested HM users.
      rekeyContainers = lib.concatMapAttrs (
        host: cfg:
        lib.mapAttrs' (cname: c: lib.nameValuePair "${host}-${cname}" { inherit (c) config; }) (
          lib.filterAttrs hasRekey (cfg.config.containers or { })
        )
      ) nixosConfigs;

      rekeyHome = lib.filterAttrs hasRekey (config.flake.homeConfigurations or { });

      # HM users embedded in a nixos/container config are rekey nodes too (the app collects them; mirror it for the check).
      homeInNixos = lib.concatMapAttrs (
        name: cfg:
        lib.mapAttrs' (u: uc: lib.nameValuePair "${name}-${u}" { config = uc; }) (
          cfg.config.home-manager.users or { }
        )
      ) (rekeyNixos // rekeyContainers);

      rekeyHomeInNixos = lib.filterAttrs hasRekey homeInNixos;

      extractExpectedFiles =
        configurations:
        lib.concatLists (
          lib.mapAttrsToList (
            _: cfg:
            let
              inherit (cfg.config.age) secrets;
              rekeyed = lib.filterAttrs (_: s: (s.rekeyFile or null) != null) secrets;
            in
            lib.mapAttrsToList (_: s: baseNameOf (toString s.file)) rekeyed
          ) configurations
        );

      expectedFiles = lib.unique (
        extractExpectedFiles rekeyNixos
        ++ extractExpectedFiles rekeyContainers
        ++ extractExpectedFiles rekeyHome
        ++ extractExpectedFiles rekeyHomeInNixos
      );

      actualFiles =
        if builtins.pathExists rekeyDir then
          lib.filter (f: lib.hasSuffix ".age" f) (builtins.attrNames (builtins.readDir rekeyDir))
        else
          [ ];

      missing = lib.filter (f: !builtins.elem f actualFiles) expectedFiles;
      orphaned = lib.filter (f: !builtins.elem f expectedFiles) actualFiles;
    in
    {
      flake.agenix-rekey = inputs.agenix-rekey.configure {
        userFlake = self;
        nixosConfigurations = rekeyNixos // rekeyContainers;
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
                  orphaned != [ ]
                ) "Orphaned files in agenix-rekey/: ${builtins.concatStringsSep ", " orphaned}\n"
                + "Run 'agenix rekey -a' to fix.";
            in
            assert missing == [ ] && orphaned == [ ] || throw msg;
            pkgs.runCommand "agenix-rekey-check" { } "touch $out";
        };
    };
in
{
  flake.flakeModules.agenix-rekey = agenix-rekey;

  imports = [ agenix-rekey ];
}
