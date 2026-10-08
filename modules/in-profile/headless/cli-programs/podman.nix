{
  flake.nixosModules.cli-programs = {
    virtualisation.podman.enable = true;
    virtualisation.containers.registries.settings.unqualified-search-registries = [ "docker.io" ];

    # Rootless container storage is covered by the persistent /home.
    # Rootful storage and custom networks must survive ephemeral-root wipes.
    my.persistence.directories = [
      "/var/lib/containers"
      "/etc/containers/networks"
    ];
  };
}
