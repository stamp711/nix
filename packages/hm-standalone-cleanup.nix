# Removes what a standalone home-manager and its nix user profile leave behind,
# on a machine that now runs home-manager inside its NixOS or nix-darwin config.
{
  perSystem =
    { config, pkgs, ... }:
    {

      # writeShellApplication runs shellcheck at build time, so building it is the check.
      checks.hm-standalone-cleanup = config.packages.hm-standalone-cleanup;

      packages.hm-standalone-cleanup = pkgs.writeShellApplication {
        name = "hm-standalone-cleanup";
        runtimeInputs = [ pkgs.coreutils ];
        text = ''
          usage="usage: hm-standalone-cleanup [--remove]"

          remove=0
          case ''${1:-} in
            "") ;;
            --remove) remove=1 ;;
            -h|--help) echo "$usage"; exit 0 ;;
            *) echo "$usage" >&2; exit 2 ;;
          esac

          # home-manager reads these the same way on Linux and darwin, so one list serves both.
          state=''${XDG_STATE_HOME:-$HOME/.local/state}
          data=''${XDG_DATA_HOME:-$HOME/.local/share}
          config=''${XDG_CONFIG_HOME:-$HOME/.config}
          user=$(id -un)
          legacy=/nix/var/nix/profiles/per-user/$user

          # An unmatched glob stays literal and fails the existence test below.
          paths=(
            # home-manager's generation profile, in each place it has lived: today's,
            # the one before nix 2.14, and the original under the nix state dir.
            "$state"/nix/profiles/home-manager
            "$state"/nix/profiles/home-manager-*-link
            "$state"/home-manager/profiles
            "$legacy"/home-manager
            "$legacy"/home-manager-*-link

            # The gcroot an older home-manager kept outside its state dir. Every
            # activation since removes it, so it only survives on a host that has not
            # activated since upgrading.
            /nix/var/nix/gcroots/per-user/"$user"/current-home

            # The home-manager CLI's own state: news-read markers, nothing else.
            "$data"/home-manager

            # The nix user profile that held home-manager-path, in both layouts. An
            # embedded home-manager installs packages into /etc/profiles/per-user instead.
            # ~/.nix-profile and ~/.nix-defexpr are not listed: every activation runs
            # `nixProfileRemove home-manager-path`, and nix-env remakes both on the way.
            "$state"/nix/profile
            "$state"/nix/profiles/profile
            "$state"/nix/profiles/profile-*-link
            "$legacy"/profile
            "$legacy"/profile-*-link

            # Channel machinery from the same era, dangling once nix.channel.enable is off.
            "$HOME"/.nix-channels
            "$state"/nix/channels
            "$state"/nix/defexpr
            "$state"/nix/profiles/channels
            "$state"/nix/profiles/channels-*-link
            "$legacy"/channels
            "$legacy"/channels-*-link
          )

          # /etc/profiles/per-user/$user appears only once an embedded home-manager with
          # useUserPackages has activated. Without it the paths below may still be live.
          if [ ! -d /etc/profiles/per-user/"$user" ]; then
            echo "warning: no /etc/profiles/per-user/$user, home-manager here may still be standalone" >&2
            [ "$remove" -eq 0 ] || { echo "refusing to remove; migrate this host first" >&2; exit 1; }
          fi

          found=0
          failed=0
          for p in "''${paths[@]}"; do
            # -L too: a symlink whose target is already gone still counts.
            [ -e "$p" ] || [ -L "$p" ] || continue
            found=$((found + 1))
            if [ "$remove" -eq 1 ]; then
              echo "removing $p"
              rm -rf -- "$p" || failed=1
            else
              echo "would remove $p"
            fi
          done

          [ "$found" -gt 0 ] || echo "nothing left over"

          # Never a leftover: an embedded home-manager reads this to find the generation
          # it is replacing, and without it the next activation aborts on every managed file.
          gcroot=$state/home-manager/gcroots/current-home
          if [ -L "$gcroot" ]; then
            echo "keeping $gcroot -> $(readlink "$gcroot")"
          else
            echo "warning: $gcroot is missing, so home-manager has no previous generation" >&2
          fi

          # Left for the operator to judge, since neither is ours to delete: one is
          # authored, the other belongs to an activation that may still be running.
          [ ! -e "$config/home-manager" ] || echo "note: $config/home-manager is your own config, left alone"
          [ ! -e "$state/home-manager/gcroots/new-home" ] || echo "note: $state/home-manager/gcroots/new-home is left by an interrupted activation"

          exit "$failed"
        '';
      };

    };
}
