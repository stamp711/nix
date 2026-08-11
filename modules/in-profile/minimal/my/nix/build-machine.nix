# Build machines: distribute builds to them, and be at most one.
{ lib, ... }:
let
  builders = lib.mkOption {
    default = { };
    description = "Build machines this machine may distribute builds to or be, one entry per machine.";
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            description = "Host the builder answers ssh on.";
          };
          hostPubkey = lib.mkOption {
            type = lib.types.str;
            description = "The key the builder's ssh server presents, which clients pin.";
          };
          clientPubkeys = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = ''
              The keys allowed to submit builds here, which only the builder itself reads.
              A client authenticates as its own ssh host key, so those are what go here.
            '';
          };
          sshUser = lib.mkOption {
            type = lib.types.str;
            description = ''
              User the client logs in as. It must be a trusted-user on the builder,
              which `serve` arranges.
            '';
          };
          systems = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "What the builder can build. nix sends it nothing else.";
          };
          supportedFeatures = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = ''
              System features the builder offers, such as big-parallel or kvm.
              nix matches a derivation's requiredSystemFeatures against them.
            '';
          };
          maxJobs = lib.mkOption {
            type = lib.types.ints.positive;
            default = 1;
            description = "How many builds the client may run there at once.";
          };
          serve = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether this machine is that builder, and so takes builds from clients.";
          };
          use = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to distribute builds to this builder.";
          };
        };
      }
    );
  };

  # The builders this machine distributes builds to, and what it must know to reach them.
  client =
    sshKey: cfg:
    let
      usedBuilders = lib.filterAttrs (_: b: b.use) cfg;
    in
    lib.mkIf (usedBuilders != { }) {
      warnings = lib.mapAttrsToList (
        name: _:
        "my.nix.build-machine.${name}: this machine both is this builder and distributes builds to it, "
        + "so every build takes a round trip through ssh to reach the store it started in."
      ) (lib.filterAttrs (_: b: b.serve && b.use) cfg);

      nix.distributedBuilds = true;
      # The builder fetches dependencies itself, so we do not push them over ssh.
      nix.settings.builders-use-substitutes = true;

      nix.buildMachines = lib.mapAttrsToList (_: b: {
        hostName = b.host;
        protocol = "ssh-ng";
        inherit (b)
          sshUser
          systems
          supportedFeatures
          maxJobs
          ;
        inherit sshKey;
      }) usedBuilders;

      programs.ssh.knownHosts = lib.mapAttrs (_: b: {
        hostNames = [ b.host ];
        publicKey = b.hostPubkey;
      }) usedBuilders;
    };

  # The builder this machine is, or null.
  servedBuilder =
    cfg:
    let
      claimed = lib.attrNames (lib.filterAttrs (_: b: b.serve) cfg);
    in
    if claimed == [ ] then
      null
    else if lib.length claimed == 1 then
      cfg.${lib.head claimed}
    else
      throw (
        "my.nix.build-machine: this machine claims ${lib.concatStringsSep ", " claimed}, "
        + "and a machine is one builder."
      );

  # This machine's own ed25519 host key, which it authenticates with.
  # nix-darwin declares hostKeys just as NixOS does, so one lookup serves both.
  identity =
    config:
    (lib.findFirst (k: k.type == "ed25519")
      (throw "my.nix.build-machine: no ed25519 host key to authenticate with")
      config.services.openssh.hostKeys
    ).path;

  buildMachine =
    { config, ... }:
    let
      mine = servedBuilder config.my.nix.build-machine;
    in
    {
      options.my.nix.build-machine = builders;

      config = lib.mkMerge [
        (client (identity config) config.my.nix.build-machine)

        (lib.mkIf (mine != null) {
          users.users.${mine.sshUser}.openssh.authorizedKeys.keys = mine.clientPubkeys;

          # ssh-ng hands the daemon derivations to build, which only a trusted user may do.
          nix.settings.trusted-users = [ mine.sshUser ];
        })
      ];
    };
in
{
  flake.nixosModules.my = buildMachine;
  flake.darwinModules.my = buildMachine;
}
