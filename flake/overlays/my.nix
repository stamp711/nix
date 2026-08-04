{ self, ... }: {
  flake.overlays.my = _final: prev: {
    my = self.packages.${prev.stdenv.hostPlatform.system};
  };
}
