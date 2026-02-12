{
  description = "PipeWire audio with ALSA and PulseAudio compatibility";

  module = {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    security.rtkit.enable = true;
  };
}
