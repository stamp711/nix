{
  description = "SSH agent switcher daemon for stable agent forwarding in tmux";

  module =
    { pkgs, lib, ... }:
    let
      # TODO: remove inline package and use pkgs.ssh-agent-switcher.overrideAttrs { doCheck = false; }
      ssh-agent-switcher = pkgs.rustPlatform.buildRustPackage rec {
        pname = "ssh-agent-switcher";
        version = "1.0.1";

        src = pkgs.fetchFromGitHub {
          owner = "jmmv";
          repo = "ssh-agent-switcher";
          tag = "ssh-agent-switcher-${version}";
          hash = "sha256-p9W0H25pWDB+GCrwLwuVruX9p8b8kICpp+6I11ym1aw=";
        };

        cargoHash = "sha256-WioA/RjXOAHM9QWl/lxnb7gqzcp76rus7Rv+IfCYceg=";

        # Integration tests fail in the Nix sandbox (no real SSH agent available)
        doCheck = false;

        nativeBuildInputs = [ pkgs.installShellFiles ];

        postInstall = ''
          installManPage ssh-agent-switcher.1
        '';

        meta = {
          description = "SSH agent forwarding and tmux done right";
          homepage = "https://github.com/jmmv/ssh-agent-switcher";
          license = lib.licenses.bsd3;
          mainProgram = "ssh-agent-switcher";
        };
      };
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
