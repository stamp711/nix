{
  flake.nixosModules.core = {
    # Some games (CS2, Star Citizen, Hogwarts Legacy) and JVM/ES workloads
    # blow past the kernel default. Matches Fedora/SteamOS default.
    boot.kernel.sysctl."vm.max_map_count" = 2147483642;
  };
}
