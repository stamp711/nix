{ lib, self, ... }: {
  flake.lib = {

    # Derive a stable secret name from a .age file path, relative to the flake root.
    # e.g. profiles/nixos/kvm-proxy/xray-proxy.env.age => profiles__nixos__kvm-proxy__xray-proxy.env
    #
    # Works for paths from any flake by stripping the /nix/store/<hash>-<name>/ prefix.
    # In flake evaluation, all paths resolve to store paths with this structure:
    #   /nix/store/abc123-source/hosts/ssh-config.age
    #   ^^^^^^^^^^^^^^^^^^^^^^^^ 4 components when split by "/": "", "nix", "store", "<hash>-<name>"
    ageSecretName =
      path:
      let
        parts = lib.splitString "/" (toString path);
        relative = lib.concatStringsSep "/" (lib.drop 4 parts);
      in
      lib.removeSuffix ".age" (builtins.replaceStrings [ "/" ] [ "__" ] relative);

    mkAgeSecret =
      config: file:
      let
        name = self.lib.ageSecretName file;
      in
      {
        inherit name;
        inherit (config.age.secrets.${name}) path;
        ageSecret.${name}.rekeyFile = file;
      };

  };
}
