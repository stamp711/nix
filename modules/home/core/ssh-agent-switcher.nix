{
  description = "SSH agent switcher daemon for stable agent forwarding in tmux";

  module =
    { pkgs, lib, ... }:
    let
      ssh-agent-switcher = pkgs.ssh-agent-switcher.overrideAttrs { doCheck = false; };
    in
    {
      home.packages = [ ssh-agent-switcher ];

      programs.zsh.loginExtra = ''
        if [ -n "$SSH_CONNECTION" ]; then
          export SSH_AUTH_SOCK="/tmp/ssh-agent-switcher.''${USER}.sock"
          ${lib.getExe ssh-agent-switcher} --daemon --socket-path="$SSH_AUTH_SOCK" 2>/dev/null || true
        fi
      '';
    };
}
