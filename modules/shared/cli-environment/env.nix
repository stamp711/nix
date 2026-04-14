# Shell environment paths, variables, and aliases
{
  flake.homeModules.cli-environment =
    { pkgs, ... }:
    {
      home.sessionPath = [
        "$HOME/.local/bin"
        "$XDG_DATA_HOME/bob/nvim-bin"
        "$VOLTA_HOME/bin"
        "$HOME/.cargo/bin"
        "/opt/homebrew/bin"
      ];

      home.sessionVariables = {
        VOLTA_HOME = "$HOME/.volta";
        COLORTERM = "truecolor";
      };

      home.shellAliases = {
        nix-init = "nix flake init -t github:the-nix-way/dev-templates#";
        sshproxy = "ssh -R 6152:127.0.0.1:6152 -R 6153:127.0.0.1:6153";
        # zsh startup benchmarking
        zsh-time = "hyperfine --warmup 3 'zsh -ic exit'";
        zsh-prof = "ZPROF=1 zsh -ic exit";
        zsh-trace = "zsh-trace-startup";
      };

      programs.zsh.initContent = ''
        zmodload zsh/net/tcp
        if ztcp 127.0.0.1 6153 2>/dev/null; then
          ztcp -c
          export {http,https}_proxy="http://127.0.0.1:6152"
          export {HTTP,HTTPS}_PROXY="http://127.0.0.1:6152"
          export {all_proxy,ALL_PROXY}="socks5://127.0.0.1:6153"
          export {no_proxy,NO_PROXY}="localhost,127.0.0.1,::1"
        fi
      '';

      home.packages = [
        (pkgs.writeShellScriptBin "zsh-trace-startup" ''
          trace_log=$(mktemp)
          PS4=$'+%D{%s.%.} %N:%i> ' zsh -xic exit 2>"$trace_log"
          ${pkgs.python3}/bin/python3 -c "
          import re, sys
          lines = open('$trace_log', errors='replace').readlines()
          timestamps = []
          for i, line in enumerate(lines):
              m = re.match(r'^\+(\d+\.\d+)\s+(.*)', line.rstrip())
              if m:
                  timestamps.append((float(m.group(1)), i, m.group(2)))
          gaps = []
          for i in range(1, len(timestamps)):
              dt = timestamps[i][0] - timestamps[i-1][0]
              if dt > 0.001:
                  gaps.append((dt, timestamps[i-1], timestamps[i]))
          gaps.sort(reverse=True)
          total = timestamps[-1][0] - timestamps[0][0] if timestamps else 0
          print(f'Total traced time: {total*1000:.0f}ms\n')
          print(f'{\"ms\":>7}  {\"what\":}')
          print(f'{\"--\":>7}  {\"----\":}')
          for dt, (t1, i1, cmd1), (t2, i2, cmd2) in gaps[:20]:
              # extract source file basename
              src = cmd2.split(':')[0] if ':' in cmd2 else '?'
              src = src.split('/')[-1]
              print(f'{dt*1000:7.1f}  {src}: {cmd2.split(\"> \", 1)[-1][:80] if \"> \" in cmd2 else cmd2[:80]}')
          "
          rm -f "$trace_log"
        '')
      ];
    };
}
