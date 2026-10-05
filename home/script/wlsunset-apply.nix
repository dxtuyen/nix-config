{ pkgs, ... }:

{
  home.file = {
    ".local/bin/wlsunset-apply" = {
      executable = true;
      text = ''
        #! /usr/bin/env bash
        # Apply a display mode and save explicit user selections.
        # Without an argument, restore the saved mode or use natural.
        set -u

        STATE="$HOME/.local/state/wlsunset-mode"
        requested="''${1:-}"
        mode=""

        if [ -n "$requested" ]; then
          mode="$requested"
        elif [ -r "$STATE" ]; then
          IFS= read -r mode < "$STATE" || true
        fi

        case "$mode" in
          warm)    args="-t 3900 -T 4000" ;;
          white)   args="-t 6400 -T 6500" ;;
          natural) args="-t 4000 -T 6500" ;;
          *)       mode="natural"; args="-t 4000 -T 6500" ;;
        esac

        # Only save the mode when explicitly requested.
        if [ -n "$requested" ]; then
          mkdir -p "''${STATE%/*}"
          printf '%s\n' "$mode" > "$STATE"
        fi

        pkill -x wlsunset 2>/dev/null || true
        for _ in {1..20}; do
          pgrep -x wlsunset >/dev/null || break
          sleep 0.05
        done
        # shellcheck disable=SC2086: expand the selected argument string.
        ${pkgs.wlsunset}/bin/wlsunset $args -l 21.0 -L 105.8 >/dev/null 2>&1 &
      '';
    };
  };
}
